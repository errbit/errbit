# MongoDB Ruby Driver Tutorial

This tutorial gives many common examples of using MongoDB with the Ruby driver. If you're looking for information on data modeling, see [MongoDB Data Modeling and Rails](http://www.mongodb.org/display/DOCS/MongoDB+Data+Modeling+and+Rails). Links to the various object mappers are listed on our [object mappers page](http://www.mongodb.org/display/DOCS/Object+Mappers+for+Ruby+and+MongoDB).

Interested in GridFS? See [GridFS in Ruby](file.GridFS.html).

As always, the [latest source for the Ruby driver](http://github.com/mongodb/mongo-ruby-driver) can be found on [github](http://github.com/mongodb/mongo-ruby-driver/).

## Installation

The mongo-ruby-driver gem is served through Rubygems.org. To install, make sure you have the latest version of rubygems.
    gem update --system
Next, install the mongo rubygem:
    gem install mongo

The required `bson` gem will be installed automatically.

For optimum performance, install the bson_ext gem:

    gem install bson_ext

After installing, you may want to look at the [examples](http://github.com/mongodb/mongo-ruby-driver/tree/master/examples) directory included in the source distribution. These examples walk through some of the basics of using the Ruby driver.

## Getting started

#### Using the gem

All of the code here assumes that you have already executed the following Ruby code:

    require 'rubygems'  # not necessary for Ruby 1.9
    require 'mongo'

#### Making a Connection

An `Mongo::Connection` instance represents a connection to MongoDB. You use a Connection instance to obtain an Mongo:DB instance, which represents a named database. The database doesn't have to exist - if it doesn't, MongoDB will create it for you.

You can optionally specify the MongoDB server address and port when connecting. The following example shows three ways to connect to the database "mydb" on the local machine:

    db = Mongo::Connection.new.db("mydb")
    db = Mongo::Connection.new("localhost").db("mydb")
    db = Mongo::Connection.new("localhost", 27017).db("mydb")

At this point, the `db` object will be a connection to a MongoDB server for the specified database. Each DB instance uses a separate socket connection to the server.

If you're trying to connect to a replica set, see [Replica Sets in Ruby](http://www.mongodb.org/display/DOCS/Replica+Sets+in+Ruby).

#### Listing All Databases

    connection = Mongo::Connection.new # (optional host/port args)
    connection.database_names.each { |name| puts name }
    connection.database_info.each { |info| puts info.inspect}

    #### Dropping a Database
    connection.drop_database('database_name')

MongoDB can be run in a secure mode where access to databases is controlled through name and password authentication.  When run in this mode, any client application must provide a name and password before doing any operations.  In the Ruby driver, you simply do the following with the connected mongo object:

    auth = db.authenticate(my_user_name, my_password)

If the name and password are valid for the database, `auth` will be `true`.  Otherwise, it will be `false`.  You should look at the MongoDB log for further information if available.

#### Getting a List Of Collections

Each database has zero or more collections.  You can retrieve a list of them from the db (and print out any that are there):

    db.collection_names.each { |name| puts name }

and assuming that there are two collections, name and address, in the database, you would see

    name
    address

as the output.

#### Getting a Collection

You can get a collection to use using the `collection` method:
    coll = db.collection("testCollection")
This is aliased to the \[\] method:
    coll = db["testCollection"]

Once you have this collection object, you can now do things like insert data, query for data, etc.

#### Inserting a Document

Once you have the collection object, you can insert documents into the collection.  For example, lets make a little document that in JSON would be represented as

      {
         "name" : "MongoDB",
         "type" : "database",
         "count" : 1,
         "info" : {
                     x : 203,
                     y : 102
                   }
      }

Notice that the above has an "inner" document embedded within it.  To do this, we can use a Hash or the driver's OrderedHash (which preserves key order) to create the document (including the inner document), and then just simply insert it into the collection using the `insert()` method.

    doc = {"name" => "MongoDB", "type" => "database", "count" => 1,
           "info" => {"x" => 203, "y" => '102'`
    coll.insert(doc)

#### Updating a Document

We can update the previous document using the `update` method. There are a couple ways to update a document. We can rewrite it:

    doc["name"] = "MongoDB Ruby"
    coll.update({"_id" => doc["_id"]}, doc)

Or we can use an atomic operator to change a single value:

    coll.update({"_id" => doc["_id"]}, {"$set" => {"name" => "MongoDB Ruby"`)

Read [more about updating documents|Updating].

#### Finding the First Document In a Collection using `find_one()`

To show that the document we inserted in the previous step is there, we can do a simple `find_one()` operation to get the first document in the collection.  This method returns a single document (rather than the `Cursor` that the `find()` operation returns).

    my_doc = coll.find_one()
    puts my_doc.inspect

and you should see:

    {"_id"=>#<BSON::ObjectID:0x118576c ...>, "name"=>"MongoDB",
     "info"=>{"x"=>203, "y"=>102}, "type"=>"database", "count"=>1}

Note the `\_id` element has been added automatically by MongoDB to your document.

#### Adding Multiple Documents

To demonstrate some more interesting queries, let's add multiple simple documents to the collection.  These documents will have the following form:
    {
       "i" : value
    }

Here's how to insert them:

    100.times { |i| coll.insert("i" => i) }

Notice that we can insert documents of different "shapes" into the same collection. These records are in the same collection as the complex record we inserted above.  This aspect is what we mean when we say that MongoDB is "schema-free".

#### Counting Documents in a Collection

Now that we've inserted 101 documents (the 100 we did in the loop, plus the first one), we can check to see if we have them all using the `count()` method.

    puts coll.count()

and it should print `101`.

#### Using a Cursor to get all of the Documents

To get all the documents from the collection, we use the `find()` method. `find()` returns a `Cursor` object, which allows us to iterate over the set of documents that matches our query.  The Ruby driver's Cursor implemented Enumerable, which allows us to use `Enumerable#each`, `Enumerable#map}, etc. For instance:

    coll.find().each { |row| puts row.inspect }

and that should print all 101 documents in the collection.

#### Getting a Single Document with a Query

We can create a _query_ hash to pass to the `find()` method to get a subset of the documents in our collection.  For example, if we wanted to find the document for which the value of the "i" field is 71, we would do the following ;

    coll.find("i" => 71).each { |row| puts row.inspect }

and it should just print just one document:

    {"_id"=>#<BSON::ObjectID:0x117de90 ...>, "i"=>71}

#### Getting a Set of Documents With a Query

We can use the query to get a set of documents from our collection.  For example, if we wanted to get all documents where "i" > 50, we could write:

    coll.find("i" => {"$gt" => 50}).each { |row| puts row }

which should print the documents where i > 50.  We could also get a range, say   20 < i <= 30:

    coll.find("i" => {"$gt" => 20, "$lte" => 30}).each { |row| puts row }

#### Selecting a subset of fields for a query

Use the `:fields` option. If you just want fields "a" and "b":

    coll.find("i" => {"$gt" => 50}, :fields => ["a", "b"]).each { |row| puts row }

#### Querying with Regular Expressions

Regular expressions can be used to query MongoDB. To find all names that begin with 'a':

    coll.find({"name" => /^a/})

You can also construct a regular expression dynamically. To match a given search string:

    search_string = params['search']

    # Constructor syntax
    coll.find({"name" => Regexp.new(search_string)})

    # Literal syntax
    coll.find({"name" => /#{search_string}/})

Although MongoDB isn't vulnerable to anything like SQL-injection, it may be worth checking the search string for anything malicious.

## Indexing

#### Creating An Index

MongoDB supports indexes, and they are very easy to add on a collection.  To create an index, you specify an index name and an array of field names to be indexed, or a single field name. The following creates an ascending index on the "i" field:

    # create_index assumes ascending order; see method docs
    # for details
    coll.create_index("i")
To specify complex indexes or a descending index you need to use a slightly more complex syntax - the index specifier must be an Array of [field name, direction] pairs. Directions should be specified as Mongo::ASCENDING or Mongo::DESCENDING:

    # Explicit "ascending"
    coll.create_index([["i", Mongo::ASCENDING]])

#### Creating and querying on a geospatial index

First, create the index on a field containing long-lat values:

    people.create_index([["loc", Mongo::GEO2D]])

Then get a list of the twenty locations nearest to the point 50, 50:

    people.find({"loc" => {"$near" => [50, 50]}}, {:limit => 20}).each do |p|
      puts p.inspect 
    end

#### Getting a List of Indexes on a Collection

You can get a list of the indexes on a collection using `coll.index_information()`.

## Database Administration

A database can have one of three profiling levels: off (:off), slow queries only (:slow_only), or all (:all). To see the database level:

    puts db.profiling_level   # => off (the symbol :off printed as a string)
    db.profiling_level = :slow_only

Validating a collection will return an interesting hash if all is well or raise an exception if there is a problem.
    p db.validate_collection('coll_name')

## See Also

* [MongoDB Koans](http://github.com/chicagoruby/MongoDB_Koans) A path to MongoDB enlightenment via the Ruby driver.
* [MongoDB Manual](http://www.mongodb.org/display/DOCS/Developer+Zone)
