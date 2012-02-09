# Write Concern in Ruby

## Setting the write concern

Write concern is set using the `:safe` option. There are several possible options:

    @collection.save({:doc => 'foo'}, :safe => true)
    @collection.save({:doc => 'foo'}, :safe => {:w => 2})
    @collection.save({:doc => 'foo'}, :safe => {:w => 2, :wtimeout => 200})
    @collection.save({:doc => 'foo'}, :safe => {:w => 2, :wtimeout => 200, :fsync => true})

The first, `true`, simply indicates that we should request a response from the server to ensure that to errors have occurred. The second, `{:w => 2}`forces the server to wait until at least two servers have recorded the write. The third does the same but will time out if the replication can't be completed in 200 milliseconds. The fourth forces an fsync on each server being written to (note: this option is rarely necessary and will have a dramaticly negative effect on performance).

## Write concern inheritance

The Ruby driver allows you to set write concern on each of four levels: the connection, database, collection, and write operation.
Objects will inherit the default write concern from their parents. Thus, if you set a write concern of `{:w => 1}` when creating
a new connection, then all databases and collections created from that connection will inherit the same setting. See this code example:

    @con = Mongo::Connection.new('localhost', 27017, :safe => {:w => 2})
    @db  = @con['test']
    @collection = @db['foo']
    @collection.save({:name => 'foo'})

    @collection.save({:name => 'bar'}, :safe => false)

Here, the first call to Collection#save will use the inherited write concern, `{:w => 2}`. But notice that the second call
to Collection#save overrides this setting.
