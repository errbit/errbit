# Replica Sets in Ruby

Here follow a few considerations for those using the MongoDB Ruby driver with [replica sets](http://www.mongodb.org/display/DOCS/Replica+Sets).

### Setup

First, make sure that you've configured and initialized a replica set.

Use `ReplSetConnection.new` to connect to a replica set. This method, which accepts a variable number of arugments,
takes a list of seed nodes followed by any connection options. You'll want to specify at least two seed nodes. This gives
the driver more chances to connect in the event that any one seed node is offline. Once the driver connects, it will
cache the replica set topology as reported by the given seed node and use that information if a failover is later required.

    @connection = ReplSetConnection.new(['n1.mydb.net', 27017], ['n2.mydb.net', 27017], ['n3.mydb.net', 27017])

### Read slaves

If you want to read from a seconday node, you can pass :read_secondary => true to ReplSetConnection#new.

    @connection = ReplSetConnection.new(['n1.mydb.net', 27017], ['n2.mydb.net', 27017], ['n3.mydb.net', 27017],
                  :read_secondary => true)

A random secondary will be chosen to be read from. In a typical multi-process Ruby application, you'll have a good distribution of reads across secondary nodes.

### Connection Failures

Imagine that either the master node or one of the read nodes goes offline. How will the driver respond?

If any read operation fails, the driver will raise a *ConnectionFailure* exception. It then becomes the client's responsibility to decide how to handle this.

If the client decides to retry, it's not guaranteed that another member of the replica set will have been promoted to master right away, so it's still possible that the driver will raise another *ConnectionFailure*. However, once a member has been promoted to master, typically within a few seconds, subsequent operations will succeed.

The driver will essentially cycle through all known seed addresses until a node identifies itself as master.

### Recovery

Driver users may wish to wrap their database calls with failure recovery code. Here's one possibility, which will attempt to connection
every half second and time out after thirty seconds.

    # Ensure retry upon failure
    def rescue_connection_failure(max_retries=60)
      retries = 0
      begin
        yield
      rescue Mongo::ConnectionFailure => ex
        retries += 1
        raise ex if retries > max_retries
        sleep(0.5)
        retry
      end
    end

    # Wrapping a call to #count()
    rescue_connection_failure do
      @db.collection('users').count()
    end

Of course, the proper way to handle connection failures will always depend on the individual application. We encourage object-mapper and application developers to publish any promising results.

### Testing

The Ruby driver (>= 1.1.5) includes unit tests for verifying replica set behavior. They reside in *tests/replica_sets*. You can run them as a group with the following rake task:

    rake test:rs

The suite will set up a five-node replica set by itself and ensure that driver behaves correctly even in the face
of individual node failures. Note that the `mongod` executable must be in the search path for this to work.

### Further Reading

* [Replica Sets](http://www.mongodb.org/display/DOCS/Replica+Set+Configuration)
* [Replics Set Configuration](http://www.mongodb.org/display/DOCS/Replica+Set+Configuration)
