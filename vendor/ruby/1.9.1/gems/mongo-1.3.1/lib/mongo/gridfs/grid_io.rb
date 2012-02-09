# encoding: UTF-8

# --
# Copyright (C) 2008-2011 10gen Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ++

require 'digest/md5'

module Mongo

  # GridIO objects represent files in the GridFS specification. This class
  # manages the reading and writing of file chunks and metadata.
  class GridIO
    DEFAULT_CHUNK_SIZE   = 256 * 1024
    DEFAULT_CONTENT_TYPE = 'binary/octet-stream'
    PROTECTED_ATTRS      = [:files_id, :file_length, :client_md5, :server_md5]

    attr_reader :content_type, :chunk_size, :upload_date, :files_id, :filename,
      :metadata, :server_md5, :client_md5, :file_length, :file_position

    # Create a new GridIO object. Note that most users will not need to use this class directly;
    # the Grid and GridFileSystem classes will instantiate this class
    #
    # @param [Mongo::Collection] files a collection for storing file metadata.
    # @param [Mongo::Collection] chunks a collection for storing file chunks.
    # @param [String] filename the name of the file to open or write.
    # @param [String] mode 'r' or 'w' or reading or creating a file.
    #
    # @option opts [Hash] :query a query selector used when opening the file in 'r' mode.
    # @option opts [Hash] :query_opts any query options to be used when opening the file in 'r' mode.
    # @option opts [String] :fs_name the file system prefix.
    # @option opts [Integer] (262144) :chunk_size size of file chunks in bytes.
    # @option opts [Hash] :metadata ({}) any additional data to store with the file.
    # @option opts [ObjectId] :_id (ObjectId) a unique id for
    #   the file to be use in lieu of an automatically generated one.
    # @option opts [String] :content_type ('binary/octet-stream') If no content type is specified,
    #   the content type will may be inferred from the filename extension if the mime-types gem can be
    #   loaded. Otherwise, the content type 'binary/octet-stream' will be used.
    # @option opts [Boolean] :safe (false) When safe mode is enabled, the chunks sent to the server
    #   will be validated using an md5 hash. If validation fails, an exception will be raised.
    def initialize(files, chunks, filename, mode, opts={})
      @files        = files
      @chunks       = chunks
      @filename     = filename
      @mode         = mode
      opts          = opts.dup
      @query        = opts.delete(:query) || {}
      @query_opts   = opts.delete(:query_opts) || {}
      @fs_name      = opts.delete(:fs_name) || Grid::DEFAULT_FS_NAME
      @safe         = opts.delete(:safe) || false
      @local_md5    = Digest::MD5.new if @safe
      @custom_attrs = {}

      case @mode
        when 'r' then init_read
        when 'w' then init_write(opts)
        else
          raise GridError, "Invalid file mode #{@mode}. Mode should be 'r' or 'w'."
      end
    end

    def [](key)
      @custom_attrs[key] || instance_variable_get("@#{key.to_s}")
    end

    def []=(key, value)
      if PROTECTED_ATTRS.include?(key.to_sym)
        warn "Attempting to overwrite protected value."
        return nil
      else
        @custom_attrs[key] = value
      end
    end

    # Read the data from the file. If a length if specified, will read from the
    # current file position.
    #
    # @param [Integer] length
    #
    # @return [String]
    #   the data in the file
    def read(length=nil)
      return '' if @file_length.zero?
      if length == 0
        return ''
      elsif length.nil? && @file_position.zero?
        read_all
      else
        read_length(length)
      end
    end
    alias_method :data, :read

    # Write the given string (binary) data to the file.
    #
    # @param [String] string
    #   the data to write
    #
    # @return [Integer]
    #   the number of bytes written.
    def write(io)
      raise GridError, "file not opened for write" unless @mode[0] == ?w
      if io.is_a? String
        if @safe
          @local_md5.update(io)
        end
        write_string(io)
      else
        length = 0
        if @safe
          while(string = io.read(@chunk_size))
            @local_md5.update(string)
            length += write_string(string)
          end
        else
          while(string = io.read(@chunk_size))
            length += write_string(string)
          end
        end
        length
      end
    end

    # Position the file pointer at the provided location.
    #
    # @param [Integer] pos
    #   the number of bytes to advance the file pointer. this can be a negative
    #   number.
    # @param [Integer] whence
    #   one of IO::SEEK_CUR, IO::SEEK_END, or IO::SEEK_SET
    #
    # @return [Integer] the new file position
    def seek(pos, whence=IO::SEEK_SET)
      raise GridError, "Seek is only allowed in read mode." unless @mode == 'r'
      target_pos = case whence
                   when IO::SEEK_CUR
                     @file_position + pos
                   when IO::SEEK_END
                     @file_length + pos
                   when IO::SEEK_SET
                     pos
                   end

      new_chunk_number = (target_pos / @chunk_size).to_i
      if new_chunk_number != @current_chunk['n']
        save_chunk(@current_chunk) if @mode[0] == ?w
        @current_chunk = get_chunk(new_chunk_number)
      end
      @file_position  = target_pos
      @chunk_position = @file_position % @chunk_size
      @file_position
    end

    # The current position of the file.
    #
    # @return [Integer]
    def tell
      @file_position
    end
    alias :pos :tell

    # Rewind the file. This is equivalent to seeking to the zeroth position.
    #
    # @return [Integer] the position of the file after rewinding (always zero).
    def rewind
      raise GridError, "file not opened for read" unless @mode[0] == ?r
      seek(0)
    end

    # Return a boolean indicating whether the position pointer is
    # at the end of the file.
    #
    # @return [Boolean]
    def eof
      raise GridError, "file not opened for read #{@mode}" unless @mode[0] == ?r
      @file_position >= @file_length
    end
    alias :eof? :eof

    # Return the next line from a GridFS file. This probably
    # makes sense only if you're storing plain text. This method
    # has a somewhat tricky API, which it inherits from Ruby's
    # StringIO#gets.
    #
    # @param [String, Integer] separator or length. If a separator,
    #   read up to the separator. If a length, read the +length+ number
    #   of bytes. If nil, read the entire file.
    # @param [Integer] length If a separator is provided, then
    #   read until either finding the separator or
    #   passing over the +length+ number of bytes.
    #
    # @return [String]
    def gets(separator="\n", length=nil)
      if separator.nil?
        read_all
      elsif separator.is_a?(Integer)
        read_length(separator)
      elsif separator.length > 1
        read_to_string(separator, length)
      else
        read_to_character(separator, length)
      end
    end

    # Return the next byte from the GridFS file.
    #
    # @return [String]
    def getc
      read_length(1)
    end

    # Creates or updates the document from the files collection that
    # stores the chunks' metadata. The file becomes available only after
    # this method has been called.
    #
    # This method will be invoked automatically when
    # on GridIO#open is passed a block. Otherwise, it must be called manually.
    #
    # @return [BSON::ObjectId]
    def close
      if @mode[0] == ?w
        if @current_chunk['n'].zero? && @chunk_position.zero?
          warn "Warning: Storing a file with zero length."
        end
        @upload_date = Time.now.utc
        id = @files.insert(to_mongo_object)
      end
      id
    end

    # Read a chunk of the data from the file and yield it to the given
    # block.
    #
    # Note that this method reads from the current file position.
    #
    # @yield Yields on chunk per iteration as defined by this file's
    #   chunk size.
    #
    # @return [Mongo::GridIO] self
    def each
      return read_all unless block_given?
      while chunk = read(chunk_size) 
        yield chunk
        break if chunk.empty?
      end
      self
    end

    def inspect
      "#<GridIO _id: #{@files_id}>"
    end

    private

    def create_chunk(n)
      chunk = BSON::OrderedHash.new
      chunk['_id']      = BSON::ObjectId.new
      chunk['n']        = n
      chunk['files_id'] = @files_id
      chunk['data']     = ''
      @chunk_position   = 0
      chunk
    end

    def save_chunk(chunk)
      @chunks.insert(chunk)
    end

    def get_chunk(n)
      chunk = @chunks.find({'files_id' => @files_id, 'n' => n}).next_document
      @chunk_position = 0
      chunk
    end

    # Read a file in its entirety.
    def read_all
      buf = ''
      if @current_chunk
        buf << @current_chunk['data'].to_s
        while buf.size < @file_length
          @current_chunk = get_chunk(@current_chunk['n'] + 1)
          break if @current_chunk.nil?
          buf << @current_chunk['data'].to_s
        end
        @file_position = @file_length
      end
      buf
    end

    # Read a file incrementally.
    def read_length(length)
      cache_chunk_data
      remaining  = (@file_length - @file_position)
      if length.nil?
        to_read = remaining
      else
        to_read = length > remaining ? remaining : length
      end
      return nil unless remaining > 0

      buf        =  ''
      while to_read > 0
        if @chunk_position == @chunk_data_length
          @current_chunk = get_chunk(@current_chunk['n'] + 1)
          cache_chunk_data
        end
        chunk_remainder = @chunk_data_length - @chunk_position
        size = (to_read >= chunk_remainder) ? chunk_remainder : to_read
        buf << @current_chunk_data[@chunk_position, size]
        to_read         -= size
        @chunk_position += size
        @file_position  += size
      end
      buf
    end

    def read_to_character(character="\n", length=nil)
      result = ''
      len = 0
      while char = getc
        result << char
        len += 1
        break if char == character || (length ? len >= length : false)
      end
      result.length > 0 ? result : nil
    end

    def read_to_string(string="\n", length=nil)
      result = ''
      len = 0
      match_idx = 0
      match_num = string.length - 1
      to_match = string[match_idx].chr
      if length
        matcher = lambda {|idx, num| idx < num && len < length }
      else
        matcher = lambda {|idx, num| idx < num}
      end
      while matcher.call(match_idx, match_num) && char = getc
        result << char
        len += 1
        if char == to_match
          while match_idx < match_num do
            match_idx += 1
            to_match = string[match_idx].chr
            char = getc
            result << char
            if char != to_match
              match_idx = 0
              to_match = string[match_idx].chr
              break
            end
          end
        end
      end
      result.length > 0 ? result : nil
    end

    def cache_chunk_data
      @current_chunk_data = @current_chunk['data'].to_s
      if @current_chunk_data.respond_to?(:force_encoding)
        @current_chunk_data.force_encoding("binary")
      end
      @chunk_data_length  = @current_chunk['data'].length
    end

    def write_string(string)
      # Since Ruby 1.9.1 doesn't necessarily store one character per byte.
      if string.respond_to?(:force_encoding)
        string.force_encoding("binary")
      end

      to_write = string.length
      while (to_write > 0) do
        if @current_chunk && @chunk_position == @chunk_size
          next_chunk_number = @current_chunk['n'] + 1
          @current_chunk    = create_chunk(next_chunk_number)
        end
        chunk_available = @chunk_size - @chunk_position
        step_size = (to_write > chunk_available) ? chunk_available : to_write
        @current_chunk['data'] = BSON::Binary.new((@current_chunk['data'].to_s << string[-to_write, step_size]).unpack("c*"))
        @chunk_position += step_size
        to_write -= step_size
        save_chunk(@current_chunk)
      end
      string.length - to_write
    end

    # Initialize the class for reading a file.
    def init_read
      doc = @files.find(@query, @query_opts).next_document
      raise GridFileNotFound, "Could not open file matching #{@query.inspect} #{@query_opts.inspect}" unless doc

      @files_id     = doc['_id']
      @content_type = doc['contentType']
      @chunk_size   = doc['chunkSize']
      @upload_date  = doc['uploadDate']
      @aliases      = doc['aliases']
      @file_length  = doc['length']
      @metadata     = doc['metadata']
      @md5          = doc['md5']
      @filename     = doc['filename']
      @custom_attrs = doc

      @current_chunk = get_chunk(0)
      @file_position = 0
    end

    # Initialize the class for writing a file.
    def init_write(opts)
      opts           = opts.dup
      @files_id      = opts.delete(:_id) || BSON::ObjectId.new
      @content_type  = opts.delete(:content_type) || (defined? MIME) && get_content_type || DEFAULT_CONTENT_TYPE
      @chunk_size    = opts.delete(:chunk_size) || DEFAULT_CHUNK_SIZE
      @metadata      = opts.delete(:metadata)
      @aliases       = opts.delete(:aliases)
      @file_length   = 0
      opts.each {|k, v| self[k] = v}
      check_existing_file if @safe

      @current_chunk = create_chunk(0)
      @file_position = 0
    end

    def check_existing_file
      if @files.find_one('_id' => @files_id)
        raise GridError, "Attempting to overwrite with Grid#put. You must delete the file first."
      end
    end

    def to_mongo_object
      h                = BSON::OrderedHash.new
      h['_id']         = @files_id
      h['filename']    = @filename if @filename
      h['contentType'] = @content_type
      h['length']      = @current_chunk ? @current_chunk['n'] * @chunk_size + @chunk_position : 0
      h['chunkSize']   = @chunk_size
      h['uploadDate']  = @upload_date
      h['aliases']     = @aliases if @aliases
      h['metadata']    = @metadata if @metadata
      h['md5']         = get_md5
      h.merge!(@custom_attrs)
      h
    end

    # Get a server-side md5 and validate against the client if running in safe mode.
    def get_md5
      md5_command            = BSON::OrderedHash.new
      md5_command['filemd5'] = @files_id
      md5_command['root']    = @fs_name
      @server_md5 = @files.db.command(md5_command)['md5']
      if @safe
        @client_md5 = @local_md5.hexdigest
        if @local_md5 == @server_md5
          @server_md5
        else
          raise GridMD5Failure, "File on server failed MD5 check"
        end
      else
        @server_md5
      end
    end

    # Determine the content type based on the filename.
    def get_content_type
      if @filename
        if types = MIME::Types.type_for(@filename)
          types.first.simplified unless types.empty?
        end
      end
    end
  end
end
