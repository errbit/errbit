# Ruby MongoDB FAQ

This is a list of frequently asked questions about using Ruby with MongoDB. If you have a question you'd like to have answered here, please post your question to the [mongodb-user list](http://groups.google.com/group/mongodb-user).

#### Can I run (insert command name here) from the Ruby driver?

Yes. You can run any of the [available database commands|List of Database Commands] from the driver using the DB#command method. The only trick is to use an OrderedHash when specifying the command. For example, here's how you'd run an asynchronous fsync from the driver:


    # This command is run on the admin database.
    @db = Mongo::Connection.new.db('admin')  

    # Build the command.
    cmd = OrderedHash.new
    cmd['fsync'] = 1
    cmd['async'] = true

    # Run it.
    @db.command(cmd)


It's important to keep in mind that some commands, like `fsync`, must be run on the `admin` database, while other commands can be run on any database. If you're having trouble, check the [command reference|List of Database Commands] to make sure you're using the command correctly.

#### Does the Ruby driver support an EXPLAIN command?

Yes. `explain` is, technically speaking, an option sent to a query that tells MongoDB to return an explain plan rather than the query's results. You can use `explain` by constructing a query and calling explain at the end:


    @collection = @db['users']
    result = @collection.find({:name => "jones"}).explain


The resulting explain plan might look something like this:


    {"cursor"=>"BtreeCursor name_1", 
     "startKey"=>{"name"=>"Jones"}, 
     "endKey"=>{"name"=>"Jones"}, 
     "nscanned"=>1.0, 
     "n"=>1, 
     "millis"=>0, 
     "oldPlan"=>{"cursor"=>"BtreeCursor name_1", 
                   "startKey"=>{"name"=>"Jones"}, 
                   "endKey"=>{"name"=>"Jones"}
     },
     "allPlans"=>[{"cursor"=>"BtreeCursor name_1", 
                     "startKey"=>{"name"=>"Jones"}, 
                     "endKey"=>{"name"=>"Jones"`]
     }


Because this collection has an index on the "name" field, the query uses that index, only having to scan a single record. "n" is the number of records the query will return. "millis" is the time the query takes, in milliseconds. "oldPlan" indicates that the query optimizer has already seen this kind of query and has, therefore, saved an efficient query plan. "allPlans" shows all the plans considered for this query.

#### I see that BSON supports a symbol type. Does this mean that I can store Ruby symbols in MongoDB?

You can store Ruby symbols in MongoDB, but only as values. BSON specifies that document keys must be strings. So, for instance, you can do this:


    @collection = @db['test']

    boat_id = @collection.save({:vehicle  => :boat})
    car_id  = @collection.save({"vehicle" => "car"})

    @collection.find_one('_id' => boat_id)
    {"_id" => ObjectID('4bb372a8238d3b5c8c000001'), "vehicle" => :boat}


    @collection.find_one('_id' => car_id)
    {"_id" => ObjectID('4bb372a8238d3b5c8c000002'), "vehicle" => "car"}


Notice that the symbol values are returned as expected, but that symbol keys are treated as strings.

#### Why can't I access random elements within a cursor?

MongoDB cursors are designed for sequentially iterating over a result set, and all the drivers, including the Ruby driver, stick closely to this directive. Internally, a Ruby cursor fetches results in batches by running a MongoDB `getmore` operation. The results are buffered for efficient iteration on the client-side.

What this means is that a cursor is nothing more than a device for returning a result set on a query that's been initiated on the server. Cursors are not containers for result sets. If we allow a cursor to be randomly accessed, then we run into issues regarding the freshness of the data. For instance, if I iterate over a cursor and then want to retrieve the cursor's first element, should a stored copy be returned, or should the cursor re-run the query? If we returned a stored copy, it may not be fresh. And if the the query is re-run, then we're technically dealing with a new cursor.

To avoid those issues, we're saying that anyone who needs flexible access to the results of a query should store those results in an array and then access the data as needed.

#### Why can't I save an instance of TimeWithZone?

MongoDB stores times in UTC as the number of milliseconds since the epoch. This means that the Ruby driver serializes Ruby Time objects only. While it would certainly be possible to serialize a TimeWithZone, this isn't preferable since the driver would still deserialize to a Time object.

All that said, if necessary, it'd be easy to write a thin wrapper over the driver that would store an extra time zone attribute and handle the serialization/deserialization of TimeWithZone transparently.

#### I keep getting CURSOR_NOT_FOUND exceptions. What's happening?

The most likely culprit here is that the cursor is timing out on the server. Whenever you issue a query, a cursor is created on the server. Cursor naturally time out after ten minutes, which means that if you happen to be iterating over a cursor for more than ten minutes, you risk a CURSOR_NOT_FOUND exception.

There are two solutions to this problem. You can either:

1. Limit your query. Use some combination of `limit` and `skip` to reduce the total number of query results. This will, obviously, bring down the time it takes to iterate.

2. Turn off the cursor timeout. To do that, invoke `find` with a block, and pass `:timeout => true`:

        @collection.find({}, :timeout => false) do |cursor|
          cursor.each do |document
            # Process documents here
          end
        end

#### I periodically see connection failures between the driver and MongoDB. Why can't the driver retry the operation automatically?

A connection failure can indicate any number of failure scenarios. Has the server crashed? Are we experiencing a temporary network partition? Is there a bug in our ssh tunnel?

Without further investigation, it's impossible to know exactly what has caused the connection failure. Furthermore, when we do see a connection failure, it's impossible to  know how many operations prior to the failure succeeded. Imagine, for instance, that we're using safe mode and we send an `$inc` operation to the server. It's entirely possible that the server has received the `$inc` but failed on the call to `getLastError`. In that case, retrying the operation would result in a double-increment.

Because of the indeterminacy involved, the MongoDB drivers will not retry operations on connection failure. How connection failures should be handled is entirely dependent on the application. Therefore, we leave it to the application developers to make the best decision in this case.

The drivers will reconnect on the subsequent operation.

#### I ocassionally get an error saying that responses are out of order. What's happening?

See (this JIRA issue)[http://jira.mongodb.org/browse/RUBY-221].
