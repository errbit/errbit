require File.dirname(__FILE__) + '/helper'
require 'hoptoad_notifier/rails/javascript_notifier'
require 'ostruct'

class JavascriptNotifierTest < Test::Unit::TestCase
  module FakeRenderer
    def javascript_tag(text)
      "<script>#{text}</script>"
    end
    def escape_javascript(text)
      "ESC#{text}ESC"
    end
  end

  class FakeController
    def self.helper_method(*args)
    end

    include HoptoadNotifier::Rails::JavascriptNotifier

    def action_name
      "action"
    end

    def controller_name
      "controller"
    end

    def request
      @request ||= OpenStruct.new
    end

    def render_to_string(options)
      context = OpenStruct.new(options[:locals])
      context.extend(FakeRenderer)
      context.instance_eval do
        erb = ERB.new(IO.read(options[:file]))
        erb.result(binding)
      end
    end
  end

  should "make sure escape_javacript is called on the request.url" do
    HoptoadNotifier.configure do
    end
    controller = FakeController.new
    controller.request.url = "bad_javascript"
    assert controller.send(:hoptoad_javascript_notifier)['"ESCbad_javascriptESC"']
    assert ! controller.send(:hoptoad_javascript_notifier)['"bad_javascript"']
  end
end

