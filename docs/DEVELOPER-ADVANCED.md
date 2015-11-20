# Some Tips to help you when you develop on Errbit

## Running spec on multi-threaded mode

Running the complete test suite can be really long. You can running it
on multi-fork system with the wonderfull gem of
[@tmm1](http://github.com/tmm1), [test-queue](http://github.com/tmm1/test-queue)

If you want do it, you need install in first the gem 'test-queue'

```
gem install test-queue
```

After you just need launch the script with adapting runner of mongoid.

```
./script/rspec_queue_mongoid.rb spec
```

In my case, the complete test suite down to 2min after a 16min long
before.

## Avoid running acceptance test with phantomjs

Some acceptance test use phantomjs to interpret the Javascript in page.
To avoid this test you can launch your test by skipping js tag

```
bundle exec rspec spec --tag="~js"
```
