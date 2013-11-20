#!/bin/bash
FILE=/tmp/bundle_done

if [ -f $FILE ]
then
	echo "File $FILE exists..."
else
    cd $STACK_PATH
    bundle exec rake db:mongoid:create_indexes
    bundle exec rake db:seed
    touch /tmp/bundle_done
fi