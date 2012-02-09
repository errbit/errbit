require './test/test_helper'
include Mongo

def read_and_write_stream(filename, read_length, opts={})
  io   = File.open(File.join(File.dirname(__FILE__), 'data', filename), 'r')
  id   = @grid.put(io, opts.merge!(:filename => filename + read_length.to_s))
  file = @grid.get(id)
  io.rewind
  data = io.read
  if data.respond_to?(:force_encoding)
    data.force_encoding("binary")
  end
  read_data = ""
  while(chunk = file.read(read_length))
    read_data << chunk
    break if chunk.empty?
  end
  assert_equal data.length, read_data.length
end

class GridTest < Test::Unit::TestCase
  context "Tests:" do
    setup do
      @db = standard_connection.db(MONGO_TEST_DB)
      @files  = @db.collection('test-fs.files')
      @chunks = @db.collection('test-fs.chunks')
    end

    teardown do
      @files.remove
      @chunks.remove
    end

    context "A one-chunk grid-stored file" do
      setup do
        @data = "GRIDDATA" * 5
        @grid = Grid.new(@db, 'test-fs')
        @id   = @grid.put(@data, :filename => 'sample',
                          :metadata => {'app' => 'photos'})
      end

      should "retrieve the file" do
        data = @grid.get(@id).data
        assert_equal @data, data
      end

    end

    context "A basic grid-stored file" do
      setup do
        @data = "GRIDDATA" * 50000
        @grid = Grid.new(@db, 'test-fs')
        @id   = @grid.put(@data, :filename => 'sample',
                          :metadata => {'app' => 'photos'})
      end

      should "check existence" do
        file = @grid.exist?(:filename => 'sample')
        assert_equal 'sample', file['filename']
      end

      should "not be able to overwrite an exising file" do
        assert_raise GridError do
          @grid.put(@data, :filename => 'sample', :_id => @id, :safe => true)
        end
      end

      should "return nil if it doesn't exist" do
        assert_nil @grid.exist?(:metadata => 'foo')
      end

      should "retrieve the stored data" do
        data = @grid.get(@id).data
        assert_equal @data.length, data.length
      end

      should "have a unique index on chunks" do
        assert @chunks.index_information['files_id_1_n_1']['unique']
      end

      should "store the filename" do
        file = @grid.get(@id)
        assert_equal 'sample', file.filename
      end

      should "store any relevant metadata" do
        file = @grid.get(@id)
        assert_equal 'photos', file.metadata['app']
      end

      should "delete the file and any chunks" do
        @grid.delete(@id)
        assert_raise GridFileNotFound do
          @grid.get(@id)
        end
        assert_equal nil, @db['test-fs']['chunks'].find_one({:files_id => @id})
      end
    end

    context "Filename not required" do
      setup do
        @data = "GRIDDATA" * 50000
        @grid = Grid.new(@db, 'test-fs')
        @metadata = {'app' => 'photos'}
      end

      should "store the file with the old filename api" do
        id = @grid.put(@data, :filename => 'sample', :metadata => @metadata)
        file = @grid.get(id)
        assert_equal 'sample', file.filename
        assert_equal @metadata, file.metadata
      end

      should "store without a filename" do
        id = @grid.put(@data, :metadata => @metadata)
        file = @grid.get(id)
        assert_nil file.filename
        file_doc = @files.find_one({'_id' => id})
        assert !file_doc.has_key?('filename')
        assert_equal @metadata, file.metadata
      end

      should "store with filename and metadata with the new api" do
        id = @grid.put(@data, :filename => 'sample', :metadata => @metadata)
        file = @grid.get(id)
        assert_equal 'sample', file.filename
        assert_equal @metadata, file.metadata
      end
    end

    context "Writing arbitrary data fields" do
      setup do
        @data = "GRIDDATA" * 50000
        @grid = Grid.new(@db, 'test-fs')
      end

      should "write random keys to the files collection" do
        id = @grid.put(@data, :phrases => ["blimey", "ahoy!"])
        file = @grid.get(id)

        assert_equal ["blimey", "ahoy!"], file['phrases']
      end

      should "ignore special keys" do
        id = @grid.put(@data, :file_length => 100, :phrase => "blimey")
        file = @grid.get(id)

        assert_equal "blimey", file['phrase']
        assert_equal 400_000, file.file_length
      end
    end

    context "Storing data with a length of zero" do
      setup do
        @grid = Grid.new(@db, 'test-fs')
        @id   = @grid.put('', :filename => 'sample',
                          :metadata => {'app' => 'photos'})
      end

      should "return the zero length" do
        data = @grid.get(@id)
        assert_equal 0, data.read.length
      end
    end

    context "Grid streaming: " do
      setup do
        @grid = Grid.new(@db, 'test-fs')
        filename = 'sample_data'
        @io   = File.open(File.join(File.dirname(__FILE__), 'data', filename), 'r')
        id    = @grid.put(@io, :filename => filename)
        @file = @grid.get(id)
        @io.rewind
        @data = @io.read
        if @data.respond_to?(:force_encoding)
          @data.force_encoding("binary")
        end
      end

      should "be equal in length" do
        @io.rewind
        assert_equal @io.read.length, @file.read.length
      end

      should "read the file" do
        read_data = ""
        @file.each do |chunk|
          read_data << chunk
        end
        assert_equal @data.length, read_data.length
      end

      should "read the file if no block is given" do
        read_data = @file.each
        assert_equal @data.length, read_data.length
      end
    end

    context "Grid streaming an empty file: " do
      setup do
        @grid = Grid.new(@db, 'test-fs')
        filename = 'empty_data'
        @io   = File.open(File.join(File.dirname(__FILE__), 'data', filename), 'r')
        id    = @grid.put(@io, :filename => filename)
        @file = @grid.get(id)
        @io.rewind
        @data = @io.read
        if @data.respond_to?(:force_encoding)
          @data.force_encoding("binary")
        end
      end

      should "be equal in length" do
        @io.rewind
        assert_equal @io.read.length, @file.read.length
      end

      should "read the file" do
        read_data = ""
        @file.each do |chunk|
          read_data << chunk
        end
        assert_equal @data.length, read_data.length
      end

      should "read the file if no block is given" do
        read_data = @file.each
        assert_equal @data.length, read_data.length
      end
    end

    context "Streaming: " do || {}
      setup do
        @grid = Grid.new(@db, 'test-fs')
      end

      should "put and get a small io object with a small chunk size" do
        read_and_write_stream('small_data.txt', 1, :chunk_size => 2)
      end

      should "put and get an empty io object" do
        read_and_write_stream('empty_data', 1)
      end

      should "put and get a small io object" do
        read_and_write_stream('small_data.txt', 1)
      end

      should "put and get a large io object if reading less than the chunk size" do
        read_and_write_stream('sample_data', 256 * 1024)
      end

      should "put and get a large io object if reading more than the chunk size" do
        read_and_write_stream('sample_data', 300 * 1024)
      end
    end
  end
end
