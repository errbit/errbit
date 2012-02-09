# GridFS in Ruby

GridFS, which stands for "Grid File Store," is a specification for storing large files in MongoDB. It works by dividing a file into manageable chunks and storing each of those chunks as a separate document. GridFS requires two collections to achieve this: one collection stores each file's metadata (e.g., name, size, etc.) and another stores the chunks themselves. If you're interested in more details, check out the [GridFS Specification](http://www.mongodb.org/display/DOCS/GridFS+Specification).

### The Grid class

The [Grid class](Mongo/Grid.html) represents the core GridFS implementation. Grid gives you a simple file store, keyed on a unique ID. This means that duplicate filenames aren't a problem. To use the Grid class, first make sure you have a database, and then instantiate a Grid:


    @db = Mongo::Connection.new.db('social_site')
    @grid = Grid.new(@db)

#### Saving files
Once you have a Grid object, you can start saving data to it. The data can be either a string or an IO-like object that responds to a #read method:


    # Saving string data
    id = @grid.put("here's some string / binary data")

    # Saving IO data and including the optional filename
    image = File.open("me.jpg")
    id2   = @grid.put(image, :filename => "me.jpg")


Grid#put returns an object id, which you can use to retrieve the file:


    # Get the string we saved
    file = @grid.get(id)

    # Get the file we saved
    image = @grid.get(id2)


#### File metadata

There are accessors for the various file attributes:


    image.filename
    # => "me.jpg"

    image.content_type
    # => "image/jpg"

    image.file_length
    # => 502357

    image.upload_date
    # => Mon Mar 01 16:18:30 UTC 2010

    # Read all the image's data at once
    image.read

    # Read the first 100k bytes of the image
    image.read(100 * 1024)


When putting a file, you can set many of these attributes and write arbitrary metadata:


    # Saving IO data
    file = File.open("me.jpg")
    id2  = @grid.put(file, 
             :filename     => "my-avatar.jpg" 
             :content_type => "application/jpg", 
             :_id          => 'a-unique-id-to-use-in-lieu-of-a-random-one',
             :chunk_size   => 100 * 1024,
             :metadata     => {'description' => "taken after a game of ultimate"})


#### Safe mode

A kind of safe mode is built into the GridFS specification. When you save a file, and MD5 hash is created on the server. If you save the file in safe mode, an MD5 will be created on the client for comparison with the server version. If the two hashes don't match, an exception will be raised.


    image = File.open("me.jpg")
    id2   = @grid.put(image, "my-avatar.jpg", :safe => true) 


#### Deleting files

Deleting a file is as simple as providing the id:


    @grid.delete(id2)


### The GridFileSystem class

[GridFileSystem](http://api.mongodb.org/ruby/current/Mongo/GridFileSystem.html) is a light emulation of a file system and therefore has a couple of unique properties. The first is that filenames are assumed to be unique. The second, a consequence of the first, is that files are versioned. To see what this means, let's create a GridFileSystem instance:

#### Saving files

    @db = Mongo::Connection.new.db("social_site")
    @fs = GridFileSystem.new(@db)

Now suppose we want to save the file 'me.jpg.' This is easily done using a filesystem-like API:


    image = File.open("me.jpg")
    @fs.open("me.jpg", "w") do |f|
      f.write image
    end 


We can then retrieve the file by filename:


    image = @fs.open("me.jpg", "r") {|f| f.read }


No problems there. But what if we need to replace the file? That too is straightforward:


    image = File.open("me-dancing.jpg")
    @fs.open("me.jpg", "w") do |f|
      f.write image
    end 


But a couple things need to be kept in mind. First is that the original 'me.jpg' will be available until the new 'me.jpg' saves. From then on, calls to the #open method will always return the most recently saved version of a file. But, and this the second point, old versions of the file won't be deleted. So if you're going to be rewriting files often, you could end up with a lot of old versions piling up. One solution to this is to use the :delete_old options when writing a file:


    image = File.open("me-dancing.jpg")
    @fs.open("me.jpg", "w", :delete_old => true) do |f|
      f.write image
    end 


This will delete all but the latest version of the file.


#### Deleting files

When you delete a file by name, you delete all versions of that file:


    @fs.delete("me.jpg")


#### Metadata and safe mode

All of the options for storing metadata and saving in safe mode are available for the GridFileSystem class:


    image = File.open("me.jpg")
    @fs.open('my-avatar.jpg', w,  
               :content_type => "application/jpg", 
               :metadata     => {'description' => "taken on 3/1/2010 after a game of ultimate"},
               :_id          => 'a-unique-id-to-use-instead-of-the-automatically-generated-one',
               :safe         => true) { |f| f.write image }


### Advanced Users

Astute code readers will notice that the Grid and GridFileSystem classes are merely thin wrappers around an underlying [GridIO class](http://api.mongodb.org/ruby/current/Mongo/GridIO.html). This means that it's easy to customize the GridFS implementation presented here; just use GridIO for all the low-level work, and build the API you need in an external manager class similar to Grid or GridFileSystem.

