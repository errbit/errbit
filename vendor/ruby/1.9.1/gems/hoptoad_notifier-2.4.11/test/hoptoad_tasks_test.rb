require File.dirname(__FILE__) + '/helper'
require 'rubygems'

require File.dirname(__FILE__) + '/../lib/hoptoad_tasks'
require 'fakeweb'

FakeWeb.allow_net_connect = false

class HoptoadTasksTest < Test::Unit::TestCase
  def successful_response(body = "")
    response = Net::HTTPSuccess.new('1.2', '200', 'OK')
    response.stubs(:body).returns(body)
    return response
  end

  def unsuccessful_response(body = "")
    response = Net::HTTPClientError.new('1.2', '200', 'OK')
    response.stubs(:body).returns(body)
    return response
  end

  context "being quiet" do
    setup { HoptoadTasks.stubs(:puts) }

    context "in a configured project" do
      setup { HoptoadNotifier.configure { |config| config.api_key = "1234123412341234" } }

      context "on deploy({})" do
        setup { @output = HoptoadTasks.deploy({}) }

        before_should "complain about missing rails env" do
          HoptoadTasks.expects(:puts).with(regexp_matches(/rails environment/i))
        end

        should "return false" do
          assert !@output
        end
      end

      context "given an optional HTTP proxy and valid options" do
        setup do
          @response   = stub("response", :body => "stub body")
          @http_proxy = stub("proxy", :post_form => @response)

          Net::HTTP.expects(:Proxy).
            with(HoptoadNotifier.configuration.proxy_host,
                 HoptoadNotifier.configuration.proxy_port,
                 HoptoadNotifier.configuration.proxy_user,
                 HoptoadNotifier.configuration.proxy_pass).
            returns(@http_proxy)

          @options    = { :rails_env => "staging", :dry_run => false }
        end
        
        context "performing a dry run" do
          setup { @output = HoptoadTasks.deploy(@options.merge(:dry_run => true)) }

          should "return true without performing any actual request" do
            assert_equal true, @output
            assert_received(@http_proxy, :post_form) do|expects|
              expects.never
            end
          end
        end

        context "on deploy(options)" do
          setup do
            @output = HoptoadTasks.deploy(@options)
          end

          before_should "post to http://hoptoadapp.com/deploys.txt" do
            URI.stubs(:parse).with('http://hoptoadapp.com/deploys.txt').returns(:uri)
            @http_proxy.expects(:post_form).with(:uri, kind_of(Hash)).returns(successful_response)
          end

          before_should "use the project api key" do
            @http_proxy.expects(:post_form).
              with(kind_of(URI), has_entries('api_key' => "1234123412341234")).
              returns(successful_response)
          end

          before_should "use send the rails_env param" do
            @http_proxy.expects(:post_form).
              with(kind_of(URI), has_entries("deploy[rails_env]" => "staging")).
              returns(successful_response)
          end

          [:local_username, :scm_repository, :scm_revision].each do |key|
            before_should "use send the #{key} param if it's passed in." do
              @options[key] = "value"
              @http_proxy.expects(:post_form).
                with(kind_of(URI), has_entries("deploy[#{key}]" => "value")).
                returns(successful_response)
            end
          end

          before_should "use the :api_key param if it's passed in." do
            @options[:api_key] = "value"
            @http_proxy.expects(:post_form).
              with(kind_of(URI), has_entries("api_key" => "value")).
              returns(successful_response)
          end

          before_should "puts the response body on success" do
            HoptoadTasks.expects(:puts).with("body")
            @http_proxy.expects(:post_form).with(any_parameters).returns(successful_response('body'))
          end

          before_should "puts the response body on failure" do
            HoptoadTasks.expects(:puts).with("body")
            @http_proxy.expects(:post_form).with(any_parameters).returns(unsuccessful_response('body'))
          end

          should "return false on failure", :before => lambda {
            @http_proxy.expects(:post_form).with(any_parameters).returns(unsuccessful_response('body'))
          } do
            assert !@output
          end

          should "return true on success", :before => lambda {
            @http_proxy.expects(:post_form).with(any_parameters).returns(successful_response('body'))
          } do
            assert @output
          end
        end
      end
    end

    context "in a configured project with custom host" do
      setup do
        HoptoadNotifier.configure do |config| 
          config.api_key = "1234123412341234"
          config.host = "custom.host"
        end
      end

      context "on deploy(:rails_env => 'staging')" do
        setup { @output = HoptoadTasks.deploy(:rails_env => "staging") }

        before_should "post to the custom host" do
          URI.stubs(:parse).with('http://custom.host/deploys.txt').returns(:uri)
          Net::HTTP.expects(:post_form).with(:uri, kind_of(Hash)).returns(successful_response)
        end
      end
    end

    context "when not configured" do
      setup { HoptoadNotifier.configure { |config| config.api_key = "" } }

      context "on deploy(:rails_env => 'staging')" do
        setup { @output = HoptoadTasks.deploy(:rails_env => "staging") }

        before_should "complain about missing api key" do
          HoptoadTasks.expects(:puts).with(regexp_matches(/api key/i))
        end

        should "return false" do
          assert !@output
        end
      end
    end
  end
end
