# Credits

Adrian Madrid, aemadrid@gmail.com

* bin/mongo_console
* examples/benchmarks.rb
* examples/irb.rb
* Modifications to examples/simple.rb
* Found plenty of bugs and missing features.
* Ruby 1.9 support.
* Gem support.
* Many other code suggestions and improvements.

Aman Gupta, aman@tmm1.net

* Collection#save
* Noted bug in returning query batch size.

Jon Crosby, jon@joncrosby.me

* Some code clean-up

John Nunemaker, http://railstips.org

* Collection#create_index takes symbols as well as strings
* Fix for Collection#save
* Add logger convenience methods to connection and database

David James, djames@sunlightfoundation.com

* Fix dates to return as UTC

Paul Dlug, paul.dlug@gmail.com

* Generate _id on the client side if not provided
* Collection#insert and Collection#save return _id

Durran Jordan, durran@gmail.com

* DB#collections
* Support for specifying sort order as array of [key, direction] pairs
* OrderedHash#update aliases to merge!

Cyril Mougel, cyril.mougel@gmail.com

* Initial logging support
* Test case

Jack Chen, chendo on github

* Test case + fix for deserializing pre-epoch Time instances

Michael Bernstein, mrb on github

* Cursor#sort

Paulo Ahahgon, pahagon on github

* removed hard limit

Les Hill, leshill on github

* OrderedHash#each returns self

Sean Cribbs, seancribbs on github

* Modified standard_benchmark to allow profiling
* C ext for faster ObjectID creation

Sunny Hirai

* Suggested hashcode fix for Mongo::ObjectID
* Noted index ordering bug.
* GridFS performance boost

Christos Trochalakis

* Added map/reduce helper

Blythe Dunham

* Added finalize option to map/reduce

Matt Powell (fauxparse)

* Added GridStore#mv

Patrick Collison

* Added safe mode for Collection#remove

Chuck Remes

* Extraction of BSON into separate gems
* Extensions compile on Rubinius
* Performance improvements for INT in C extensions
* Performance improvements for JRuby BSON encoder and callback classes

Dmitrii Golub (Houdini) and Jacques Crocker (railsjedi)

* Support open to exclude fields on query

dfitzgibbon

* patch for ensuring bson_ext compatibility with early release of Ruby 1.8.5

Matt Taylor

* Noticed excessive calls to ObjectId#to_s. As a result, stopped creating
log messages when no logger was passed to Mongo::Connection. Resulted in a significant
performance improvement.

Hongli Lai (Phusion)

* Significant performance improvements. See commits.

Mislav Marohnić

* Replaced returning with each_with_object

Alex Stupka

* Replica set port bug
