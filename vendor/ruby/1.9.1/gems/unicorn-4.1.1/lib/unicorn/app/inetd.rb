# -*- encoding: binary -*-
# :enddoc:
# Copyright (c) 2009 Eric Wong
# You can redistribute it and/or modify it under the same terms as Ruby.

# this class *must* be used with Rack::Chunked
module Unicorn::App
  class Inetd < Struct.new(:cmd)

    class CatBody < Struct.new(:errors, :err_rd, :out_rd, :pid_map)
      def initialize(env, cmd)
        self.errors = env['rack.errors']
        in_rd, in_wr = IO.pipe
        self.err_rd, err_wr = IO.pipe
        self.out_rd, out_wr = IO.pipe

        cmd_pid = fork {
          inp, out, err = (0..2).map { |i| IO.new(i) }
          inp.reopen(in_rd)
          out.reopen(out_wr)
          err.reopen(err_wr)
          [ in_rd, in_wr, err_rd, err_wr, out_rd, out_wr ].each { |i| i.close }
          exec(*cmd)
        }
        [ in_rd, err_wr, out_wr ].each { |io| io.close }
        [ in_wr, err_rd, out_rd ].each { |io| io.binmode }
        in_wr.sync = true

        # Unfortunately, input here must be processed inside a seperate
        # thread/process using blocking I/O since env['rack.input'] is not
        # IO.select-able and attempting to make it so would trip Rack::Lint
        inp_pid = fork {
          input = env['rack.input']
          [ err_rd, out_rd ].each { |io| io.close }

          # this is dependent on input.read having readpartial semantics:
          buf = input.read(16384)
          begin
            in_wr.write(buf)
          end while input.read(16384, buf)
        }
        in_wr.close
        self.pid_map = {
          inp_pid => 'input streamer',
          cmd_pid => cmd.inspect,
        }
      end

      def each
        begin
          rd, = IO.select([err_rd, out_rd])
          rd && rd.first or next

          if rd.include?(err_rd)
            begin
              errors.write(err_rd.read_nonblock(16384))
            rescue Errno::EINTR
            rescue Errno::EAGAIN
              break
            end while true
          end

          rd.include?(out_rd) or next

          begin
            yield out_rd.read_nonblock(16384)
          rescue Errno::EINTR
          rescue Errno::EAGAIN
            break
          end while true
        rescue EOFError,Errno::EPIPE,Errno::EBADF,Errno::EINVAL
          break
        end while true

        self
      end

      def close
        pid_map.each { |pid, str|
          begin
            pid, status = Process.waitpid2(pid)
            status.success? or
              errors.write("#{str}: #{status.inspect} (PID:#{pid})\n")
          rescue Errno::ECHILD
            errors.write("Failed to reap #{str} (PID:#{pid})\n")
          end
        }
        out_rd.close
        err_rd.close
      end

    end

    def initialize(*cmd)
      self.cmd = cmd
    end

    def call(env)
      /\A100-continue\z/i =~ env[Unicorn::Const::HTTP_EXPECT] and
          return [ 100, {} , [] ]

      [ 200, { 'Content-Type' => 'application/octet-stream' },
       CatBody.new(env, cmd) ]
    end

  end

end
