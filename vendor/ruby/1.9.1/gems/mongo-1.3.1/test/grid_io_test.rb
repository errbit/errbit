require './test/test_helper'

class GridIOTest < Test::Unit::TestCase

  context "GridIO" do
    setup do
      @db = standard_connection.db(MONGO_TEST_DB)
      @files  = @db.collection('fs.files')
      @chunks = @db.collection('fs.chunks')
      @chunks.create_index([['files_id', Mongo::ASCENDING], ['n', Mongo::ASCENDING]])
    end

    teardown do
      @files.remove
      @chunks.remove
    end

    context "Options" do
      setup do
        @filename = 'test'
        @mode     = 'w'
      end

      should "set default 256k chunk size" do
        file = GridIO.new(@files, @chunks, @filename, @mode)
        assert_equal 256 * 1024, file.chunk_size
      end

      should "set chunk size" do
        file = GridIO.new(@files, @chunks, @filename, @mode, :chunk_size => 1000)
        assert_equal 1000, file.chunk_size
      end
    end

    context "StringIO methods" do
      setup do
        @filename = 'test'
        @mode     = 'w'
        @data     = "012345678\n" * 100000
        @file = GridIO.new(@files, @chunks, @filename, @mode)
        @file.write(@data)
        @file.close
      end

      should "read data character by character using" do
        bytes = 0
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        while char = file.getc
          bytes += 1
        end
        assert_equal bytes, 1_000_000
      end

      should "read length is a length is given" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.gets(1000)
        assert_equal string.length, 1000
        bytes = 0
        bytes += string.length
        while string = file.gets(1000)
          bytes += string.length
        end
        assert_equal bytes, 1_000_000
      end

      should "read to the end of the line by default and assign to $_" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.gets
        assert_equal 10, string.length
      end

      should "read to the end of the file one line at a time" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        bytes = 0
        while string = file.gets
          bytes += string.length
        end
        assert_equal 1_000_000, bytes
      end

      should "read to the end of the file one multi-character separator at a time" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        bytes = 0
        while string = file.gets("45")
          bytes += string.length
        end
        assert_equal 1_000_000, bytes
      end

      should "read to a given separator" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.gets("5")
        assert_equal 6, string.length
      end

      should "read a multi-character separator" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.gets("45")
        assert_equal 6, string.length
        string = file.gets("45")
        assert_equal "678\n012345", string
        string = file.gets("\n01")
        assert_equal "678\n01", string
      end

      should "read a mult-character separator with a length" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.gets("45", 3)
        assert_equal 3, string.length
      end

      should "tell position, eof, and rewind" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        string = file.read(1000)
        assert_equal 1000, file.pos
        assert !file.eof?
        file.read
        assert file.eof?
        file.rewind
        assert_equal 0, file.pos
        assert_equal 1_000_000, file.read.length
      end
    end

    context "Seeking" do
      setup do
        @filename = 'test'
        @mode     = 'w'
        @data     = "1" * 1024 * 1024
        @file = GridIO.new(@files, @chunks, @filename, @mode)
        @file.write(@data)
        @file.close
      end

      should "read all data using read_length and then be able to seek" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        assert_equal @data, file.read(1024 * 1024)
        file.seek(0)
        assert_equal @data, file.read
      end

      should "read all data using read_all and then be able to seek" do
        file = GridIO.new(@files, @chunks, nil, "r", :query => {:_id => @file.files_id})
        assert_equal @data, file.read
        file.seek(0)
        assert_equal @data, file.read
        file.seek(1024 * 512)
        assert_equal 524288, file.file_position
        assert_equal @data.length / 2, file.read.length
        assert_equal 1048576, file.file_position
        assert_nil file.read
        file.seek(1024 * 512)
        assert_equal 524288, file.file_position
      end

    end

    context "Grid MD5 check" do
      should "run in safe mode" do
        file = GridIO.new(@files, @chunks, 'smallfile', 'w', :safe => true)
        file.write("DATA" * 100)
        assert file.close
        assert_equal file.server_md5, file.client_md5
      end

      should "validate with a large file" do
        io = File.open(File.join(File.dirname(__FILE__), 'data', 'sample_file.pdf'), 'r')
        file = GridIO.new(@files, @chunks, 'bigfile', 'w', :safe => true)
        file.write(io)
        assert file.close
        assert_equal file.server_md5, file.client_md5
      end

      should "raise an exception when check fails" do
        io = File.open(File.join(File.dirname(__FILE__), 'data', 'sample_file.pdf'), 'r')
        @db.stubs(:command).returns({'md5' => '12345'})
        file = GridIO.new(@files, @chunks, 'bigfile', 'w', :safe => true)
        file.write(io)
        assert_raise GridMD5Failure do
          assert file.close
        end
        assert_not_equal file.server_md5, file.client_md5
      end
    end

    context "Content types" do
      if defined?(MIME)
        should "determine common content types from the extension" do
          file = GridIO.new(@files, @chunks, 'sample.pdf', 'w')
          assert_equal 'application/pdf', file.content_type

          file = GridIO.new(@files, @chunks, 'sample.txt', 'w')
          assert_equal 'text/plain', file.content_type
        end
      end

      should "default to binary/octet-stream when type is unknown" do
        file = GridIO.new(@files, @chunks, 'sample.l33t', 'w')
        assert_equal 'binary/octet-stream', file.content_type
      end

      should "use any provided content type by default" do
        file = GridIO.new(@files, @chunks, 'sample.l33t', 'w', :content_type => 'image/jpg')
        assert_equal 'image/jpg', file.content_type
      end
    end
  end

end
