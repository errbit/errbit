# Changelog

## 1.7.6

* Support for the HTTPClient's request_filter feature

   Thanks to [Roman Shterenzon](https://github.com/romanbsd)

## 1.7.5

* Added support for Patron 0.4.15. This change is not backward compatible so please upgrade Patron to version >= 0.4.15 if you want to use it with WebMock.

   Thanks to [Andreas Garnæs](https://github.com/andreas)

## 1.7.4

* Added support for matching EM-HTTP-Request requests with body declared as a Hash

   Thanks to [David Yeu](https://github.com/daveyeu)

## 1.7.3

* Added `Get`, `Post`, `Delete`, `Put`, `Head`, `Option` constants to replaced `Net::HTTP` to make it possible to marshal objects with these constants assigned to properties. This fixed problem with `tvdb_party` gem which serializes HTTParty responses.

  Thanks to [Klaus Hartl](https://github.com/carhartl) for reporting this issue.

## 1.7.2

* Redefined `const_get` and `constants` methods on the replaced `Net::HTTP` to return same values as original `Net::HTTP`

## 1.7.1

* Redefined `const_defined?` on the replaced `Net::HTTP` so that it returns true if constant is defined on the original `Net::HTTP`. This fixes problems with `"Net::HTTP::Get".constantize`.

   Thanks to [Cássio Marques](https://github.com/cassiomarques) for reporting the issue and to [Myron Marston](https://github.com/myronmarston) for help with the solution.

## 1.7.0

* Fixed Net::HTTP adapter to not break normal Net::HTTP behaviour when network connections are allowed. This fixes **selenium-webdriver compatibility**!!!

* Added support for EM-HTTP-Request 1.0.x and EM-Synchrony. Thanks to [Steve Hull](https://github.com/sdhull)

* Added support for setting expectations to on a stub itself i.e.

        stub = stub_request(:get, "www.example.com")
        # ... make requests ...
        stub.should have_been_requested

  Thanks to [Aidan Feldman](https://github.com/afeld)

* Minitest support! Thanks to [Peter Higgins](https://github.com/phiggins)

* Added support for Typhoeus::Hydra

* Added support for `Curb::Easy#http_post` and `Curb::Easy#http_post` with multiple arguments. Thanks to [Salvador Fuentes Jr](https://github.com/fuentesjr) and [Alex Rothenberg](https://github.com/alexrothenberg)

* Rack support. Requests can be stubbed to respond with a Rack app i.e.

        class MyRackApp
          def self.call(env)
            [200, {}, ["Hello"]]
          end
        end

        stub_request(:get, "www.example.com").to_rack(MyRackApp)

        RestClient.get("www.example.com") # ===> "Hello"


    Thanks to [Jay Adkisson](https://github.com/jayferd)

* Added support for selective disabling and enabling of http lib adapters

        WebMock.disable!                         #disable WebMock (all adapters)
        WebMock.disable!(:except => [:net_http]) #disable WebMock for all libs except Net::HTTP
        WebMock.enable!                          #enable WebMock (all adapters)
        WebMock.enable!(:except => [:patron])    #enable WebMock for all libs except Patron

* The error message on an unstubbed request shows a code snippet with body as a hash when it was in url encoded form.

        > RestClient.post('www.example.com', "data[a]=1&data[b]=2", :content_type => 'application/x-www-form-urlencoded')

        WebMock::NetConnectNotAllowedError: Real HTTP connections are disabled....

        You can stub this request with the following snippet:

        stub_request(:post, "http://www.example.com/").
          with(:body => {"data"=>{"a"=>"1", "b"=>"2"}},
               :headers => { 'Content-Type'=>'application/x-www-form-urlencoded' }).
          to_return(:status => 200, :body => "", :headers => {})

    Thanks to [Alex Rothenberg](https://github.com/alexrothenberg)

* The error message on an unstubbed request shows currently registered request stubs.

        > stub_request(:get, "www.example.net")
        > stub_request(:get, "www.example.org")
        > RestClient.get("www.example.com")
        WebMock::NetConnectNotAllowedError: Real HTTP connections are disabled....

        You can stub this request with the following snippet:

        stub_request(:get, "http://www.example.com/").
          to_return(:status => 200, :body => "", :headers => {})

        registered request stubs:

        stub_request(:get, "http://www.example.net/")
        stub_request(:get, "http://www.example.org/")

    Thanks to [Lin Jen-Shin](https://github.com/godfat) for suggesting this feature.

* Fixed problem with matching requests with json body, when json strings have date format. Thanks to [Joakim Ekberg](https://github.com/kalasjocke) for reporting this issue.

* WebMock now attempts to require each http library before monkey patching it. This is to avoid problem when http library is required after WebMock is required. Thanks to [Myron Marston](https://github.com/myronmarston) for suggesting this change.

* External requests can be disabled while allowing selected ports on selected hosts

        WebMock.disable_net_connect!(:allow => "www.example.com:8080")
        RestClient.get("www.example.com:80") # ===> Failure
        RestClient.get("www.example.com:8080")  # ===> Allowed.

    Thanks to [Zach Dennis](https://github.com/zdennis)

* Fixed syntax error in README examples, showing the ways of setting request expectations. Thanks to [Nikita Fedyashev](https://github.com/nfedyashev)


**Many thanks to WebMock co-maintainer [James Conroy-Finn](https://github.com/jcf) who did a great job maintaining WebMock on his own for the last couple of months.**

## 1.6.4

This is a quick slip release to regenerate the gemspec. Apparently
jeweler inserts dependencies twice if you use the `gemspec` method in
your Gemfile and declare gem dependencies in your gemspec.

https://github.com/technicalpickles/jeweler/issues/154

josevalim:

> This just bit me. I just released a gem with the wrong dependencies
> because I have updated jeweler. This should have been opt-in,
> otherwise a bunch of people using jeweler are going to release gems
> with the wrong dependencies because you are automatically importing
> from the Gemfile.

## 1.6.3

* Update the dependency on addressable to get around an issue in v2.2.5.
  Thanks to [Peter Higgins](https://github.com/phiggins).

* Add support for matching parameter values using a regular expression
  as well as a string. Thanks to [Oleg M Prozorov](https://github.com/oleg).

* Fix integration with httpclient as the internal API has changed.
  Thanks to [Frank Prößdorf](https://github.com/endor).

* Ensure Curl::Easy#content_type is always set. Thanks to [Peter
  Higgins](https://github.com/phiggins).

* Fix bug with em-http-request adapter stubbing responses that have a
  chunked transfer encoding. Thanks to [Myron
  Marston](https://github.com/myronmarston).

* Fix a load of spec failures with Patron, httpclient, and specs that
  depended on the behaviour of example.com. Thanks to [Alex
  Grigorovich](https://github.com/grig).

## 1.6.2

* Em-http-request adapter sets `last_effective_url` property. Thanks to [Sam Stokes](https://github.com/samstokes).

* Curb adapter supports `Curb::Easy#http_post` and `Curb::Easy#http_put` without arguments (by setting `post_body` or `put_data` beforehand). Thanks to [Eugene Bolshakov](https://github.com/eugenebolshakov)

## 1.6.1

* Fixed issue with `webmock/rspec` which didn't load correctly if `rspec/core` was already required but `rspec/expectations` not.

## 1.6.0

* Simplified integration with Test::Unit, RSpec and Cucumber. Now only a single file has to be required i.e.

                require 'webmock/test_unit'
                require 'webmock/rspec'
                require 'webmock/cucumber'

* The error message on unstubbed request now contains code snippet which can be used to stub this request. Thanks to Martyn Loughran for suggesting this feature.

* The expectation failure message now contains a list of made requests. Thanks to Martyn Loughran for suggesting this feature.

* Added `WebMock.print_executed_requests` method which can be useful to find out what requests were made until a given point.

* em-http-request adapter is now activated by replacing EventMachine::HttpRequest constant, instead of monkeypatching the original class.

 This technique is borrowed from em-http-request native mocking module. It allows switching WebMock adapter on an off, and using it interchangeably with em-http-request native mocking i.e:

                EventMachine::WebMockHttpRequest.activate!
                EventMachine::WebMockHttpRequest.deactivate!

        Thanks to Martyn Loughran for suggesting this feature.

* `WebMock.reset_webmock` is deprecated in favour of new `WebMock.reset!`

* Fixed integration with Cucumber. Previously documented example didn't work with new versions of Cucumber.

* Fixed stubbing requests with body declared as a hash. Thanks to Erik Michaels-Ober for reporting the issue.

* Fixed issue with em-http-request adapter which didn't work when :query option value was passed as a string, not a hash. Thanks to Chee Yeo for reporting the issue.

* Fixed problem with assert_requested which didn't work if used outside rspec or test/unit

* Removed dependency on json gem

## 1.5.0

* Support for dynamically evaluated raw responses recorded with `curl -is` <br/>
  i.e.

                `curl -is www.example.com > /tmp/www.example.com.txt`
                stub_request(:get, "www.example.com").to_return(lambda { |request| File.new("/tmp/#{request.uri.host.to_s}.txt" }))

* `:net_http_connect_on_start` option can be passed to `WebMock.allow_net_connect!` and `WebMock.disable_net_connect!` methods, i.e.

                WebMock.allow_net_connect!(:net_http_connect_on_start => true)

  This forces WebMock Net::HTTP adapter to always connect on `Net::HTTP.start`. Check 'Connecting on Net::HTTP.start' in README for more information.

  Thanks to Alastair Brunton for reporting the issue and for fix suggestions.

* Fixed an issue where Patron spec tried to remove system temporary directory.
  Thanks to Hans de Graaff

* WebMock specs now use RSpec 2

* `rake spec NO_CONNECTION=true` can now be used to only run WebMock specs which do not make real network connections

## 1.4.0

* Curb support!!! Thanks to the awesome work of Pete Higgins!

* `include WebMock` is now deprecated to avoid method and constant name conflicts. Please `include WebMock::API` instead.

* `WebMock::API#request` is renamed to `WebMock::API#a_request` to prevent method name conflicts with i.e. Rails controller specs.
  WebMock.request is still available.

* Deprecated `WebMock#request`, `WebMock#allow_net_connect!`, `WebMock#net_connect_allowed?`, `WebMock#registered_request?`, `WebMock#reset_callbacks`, `WebMock#after_request` instance methods. These methods are still available, but only as WebMock class methods.

* Removed `WebMock.response_for_request` and `WebMock.assertion_failure` which were only used internally and were not documented.

* :allow_localhost => true' now permits 0.0.0.0 in addition to 127.0.0.1 and 'localhost'. Thanks to Myron Marston and Mike Gehard for suggesting this.

* Fixed issue with both RSpec 1.x and 2.x being available.

  WebMock now tries to use already loaded version of RSpec (1.x or 2.x). Previously it was loading RSpec 2.0 if available, even if RSpec 1.3 was already loaded.

  Thanks to Hans de Graaff for reporting this.

* Changed runtime dependency on Addressable version 2.2.2 which fixes handling of percent-escaped '+'

## 1.3.5

* External requests can be disabled while allowing selected hosts. Thanks to Charles Li and Ryan Bigg

  This feature was available before only for localhost with `:allow_localhost => true`

                WebMock.disable_net_connect!(:allow => "www.example.org")

                Net::HTTP.get('www.something.com', '/')   # ===> Failure

                Net::HTTP.get('www.example.org', '/')      # ===> Allowed.

* Fixed Net::HTTP adapter so that it preserves the original behavior of Net::HTTP.

  When making a request with a block that calls #read_body on the request,
  Net::HTTP causes the body to be set to a Net::ReadAdapter, but WebMock was causing the body to be set to a string.

## 1.3.4

* Fixed Net::HTTP adapter to handle cases where a block with `read_body` call is passed to `request`.
  This fixes compatibility with `open-uri`. Thanks to Mark Evans for reporting the issue.

## 1.3.3

* Fixed handling of multiple values for the same response header for Net::HTTP. Thanks to Myron Marston for reporting the issue.

## 1.3.2

* Fixed compatibility with EM-HTTP-Request >= 0.2.9. Thanks to Myron Marston for reporting the issue.

## 1.3.1

* The less hacky way to get the stream behaviour working for em-http-request. Thanks to Martyn Loughran

* Fixed issues where Net::HTTP was not accepting valid nil response body. Thanks to Muness Alrubaie

## 1.3.0

* Added support for [em-http-request](http://github.com/igrigorik/em-http-request)

* Matching query params using a hash

                 stub_http_request(:get, "www.example.com").with(:query => {"a" => ["b", "c"]})

                 RestClient.get("http://www.example.com/?a[]=b&a[]=c") # ===> Success

                 request(:get, "www.example.com").with(:query => {"a" => ["b", "c"]}).should have_been_made  # ===> Success

* Matching request body against a hash. Body can be URL-Encoded, JSON or XML.

  (Thanks to Steve Tooke for the idea and a solution for url-encoded bodies)

                stub_http_request(:post, "www.example.com").
                        with(:body => {:data => {:a => '1', :b => 'five'}})

                RestClient.post('www.example.com', "data[a]=1&data[b]=five",
                :content_type => 'application/x-www-form-urlencoded')    # ===> Success

                RestClient.post('www.example.com', '{"data":{"a":"1","b":"five"}}',
                :content_type => 'application/json')    # ===> Success

                RestClient.post('www.example.com', '<data a="1" b="five" />',
                        :content_type => 'application/xml' )    # ===> Success

                request(:post, "www.example.com").
        with(:body => {:data => {:a => '1', :b => 'five'}},
         :headers => 'Content-Type' => 'application/json').should have_been_made         # ===> Success

* Request callbacks (Thanks to Myron Marston for all suggestions)

    WebMock can now invoke callbacks for stubbed or real requests:

                WebMock.after_request do |request_signature, response|
                  puts "Request #{request_signature} was made and #{response} was returned"
                end

    invoke callbacks for real requests only and except requests made with Patron client

                WebMock.after_request(:except => [:patron], :real_requests_only => true)  do |request_signature, response|
                  puts "Request #{request_signature} was made and #{response} was returned"
                end

* `to_raise()` now accepts an exception instance or a string as argument in addition to an exception class

                stub_request(:any, 'www.example.net').to_raise(StandardError.new("some error"))

                stub_request(:any, 'www.example.net').to_raise("some error")

* Matching requests based on a URI is 30% faster

* Fixed constant namespace issues in HTTPClient adapter. Thanks to Nathaniel Bibler for submitting a patch.

## 1.2.2

* Fixed problem where ArgumentError was raised if query params were made up of an array e.g. data[]=a&data[]=b. Thanks to Steve Tooke

## 1.2.1

* Changed license from GPL to MIT

* Fixed gemspec file. Thanks to Razic

## 1.2.0

* RSpec 2 compatibility. Thanks to Sam Phillips!

* :allow_localhost => true' now permits 127.0.0.1 as well as 'localhost'. Thanks to Mack Earnhardt

* Request URI matching in now 2x faster!


## 1.1.0

* [VCR](http://github.com/myronmarston/vcr/) compatibility. Many thanks to Myron Marston for all suggestions.

* Support for stubbing requests and returning responses with multiple headers with the same name. i.e multiple Accept headers.

                stub_http_request(:get, 'www.example.com').
                  with(:headers => {'Accept' => ['image/png', 'image/jpeg']}).
                  to_return(:body => 'abc')
                RestClient.get('www.example.com',
                 {"Accept" => ['image/png', 'image/jpeg']}) # ===> "abc\n"

* When real net connections are disabled and unstubbed request is made, WebMock throws WebMock::NetConnectNotAllowedError instead of assertion error or StandardError.

* Added WebMock.version()


## 1.0.0

* Added support for [Patron](http://toland.github.com/patron/)

* Responses dynamically evaluated from block (idea and implementation by Tom Ward)

                stub_request(:any, 'www.example.net').
                     to_return { |request| {:body => request.body} }

                RestClient.post('www.example.net', 'abc')    # ===> "abc\n"

* Responses dynamically evaluated from lambda (idea and implementation by Tom Ward)

        stub_request(:any, 'www.example.net').
              to_return(lambda { |request| {:body => request.body} })

            RestClient.post('www.example.net', 'abc')    # ===> "abc\n"

* Response with custom status message

                stub_request(:any, "www.example.com").to_return(:status => [500, "Internal Server Error"])

                req = Net::HTTP::Get.new("/")
                Net::HTTP.start("www.example.com") { |http| http.request(req) }.message # ===> "Internal Server Error"

* Raising timeout errors (suggested by Jeffrey Jones) (compatibility with Ruby 1.8.6 by Mack Earnhardt)

                stub_request(:any, 'www.example.net').to_timeout

                RestClient.post('www.example.net', 'abc')    # ===> RestClient::RequestTimeout

* External requests can be disabled while allowing localhost (idea and implementation by Mack Earnhardt)

                WebMock.disable_net_connect!(:allow_localhost => true)

                Net::HTTP.get('www.something.com', '/')   # ===> Failure

                Net::HTTP.get('localhost:9887', '/')      # ===> Allowed. Perhaps to Selenium?


### Bug fixes

* Fixed issue where Net::HTTP adapter didn't work for requests with body responding to read (reported by Tekin Suleyman)
* Fixed issue where request stub with headers declared as nil was matching requests with non empty headers

## 0.9.1

* Fixed issue where response status code was not read from raw (curl -is) responses

## 0.9.0

* Matching requests against provided block (by Sergio Gil)

                stub_request(:post, "www.example.com").with { |request| request.body == "abc" }.to_return(:body => "def")
                RestClient.post('www.example.com', 'abc')    # ===> "def\n"
                request(:post, "www.example.com").with { |req| req.body == "abc" }.should have_been_made
                #or
                assert_requested(:post, "www.example.com") { |req| req.body == "abc" }

* Matching request body against regular expressions (suggested by Ben Pickles)

                stub_request(:post, "www.example.com").with(:body => /^.*world$/).to_return(:body => "abc")
                RestClient.post('www.example.com', 'hello world')    # ===> "abc\n"

* Matching request headers against regular expressions (suggested by Ben Pickles)

                stub_request(:post, "www.example.com").with(:headers => {"Content-Type" => /image\/.+/}).to_return(:body => "abc")
                RestClient.post('www.example.com', '', {'Content-Type' => 'image/png'})    # ===> "abc\n"

* Replaying raw responses recorded with `curl -is`

                `curl -is www.example.com > /tmp/example_curl_-is_output.txt`
                raw_response_file = File.new("/tmp/example_curl_-is_output.txt")

        from file

                stub_request(:get, "www.example.com").to_return(raw_response_file)

        or string

                stub_request(:get, "www.example.com").to_return(raw_response_file.read)

* Multiple responses for repeated requests

                stub_request(:get, "www.example.com").to_return({:body => "abc"}, {:body => "def"})
                Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
                Net::HTTP.get('www.example.com', '/')    # ===> "def\n"

* Multiple responses using chained `to_return()` or `to_raise()` declarations

                stub_request(:get, "www.example.com").
                        to_return({:body => "abc"}).then.  #then() just is a syntactic sugar
                        to_return({:body => "def"}).then.
                        to_raise(MyException)
                Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
                Net::HTTP.get('www.example.com', '/')    # ===> "def\n"
                Net::HTTP.get('www.example.com', '/')    # ===> MyException raised

* Specifying number of times given response should be returned

                stub_request(:get, "www.example.com").
                        to_return({:body => "abc"}).times(2).then.
                        to_return({:body => "def"})

                Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
                Net::HTTP.get('www.example.com', '/')    # ===> "abc\n"
                Net::HTTP.get('www.example.com', '/')    # ===> "def\n"

* Added support for `Net::HTTP::Post#body_stream`

        This fixes compatibility with new versions of RestClient

* WebMock doesn't suppress default request headers added by http clients anymore.

        i.e. Net::HTTP adds `'Accept'=>'*/*'` to all requests by default



## 0.8.2

  * Fixed issue where WebMock was not closing IO object passed as response body after reading it.
  * Ruby 1.9.2 compat: Use `File#expand_path` for require path because "." is not be included in LOAD_PATH since Ruby 1.9.2


## 0.8.1

  * Fixed HTTPClient adapter compatibility with Ruby 1.8.6 (reported by Piotr Usewicz)
  * Net:HTTP adapter now handles request body assigned as Net::HTTP::Post#body attribute (fixed by Mack Earnhardt)
  * Fixed issue where requests were not matching stubs with Accept header set.(reported by Piotr Usewicz)
  * Fixed compatibility with Ruby 1.9.1, 1.9.2 and JRuby 1.3.1 (reported by Diego E. “Flameeyes” Pettenò)
  * Fixed issue with response body declared as IO object and multiple requests (reported by Niels Meersschaert)
  * Fixed "undefined method `assertion_failure'" error (reported by Nick Plante)


## 0.8.0

  * Support for HTTPClient (sync and async requests)
  * Support for dynamic responses. Response body and headers can be now declared as lambda.
        (Thanks to Ivan Vega ( @ivanyv ) for suggesting this feature)
  * Support for stubbing and expecting requests with empty body
  * Executing non-stubbed request leads to failed expectation instead of error


### Bug fixes

  * Basic authentication now works correctly
  * Fixed problem where WebMock didn't call a block with the response when block was provided
  * Fixed problem where uris with single slash were not matching uris without path provided


## 0.7.3

  * Clarified documentation
  * Fixed some issues with loading of Webmock classes
  * Test::Unit and RSpec adapters have to be required separately


## 0.7.2

  * Added support for matching escaped and non escaped URLs
