require "spec_helper"
require "heroku/command/stack"

module Heroku::Command
  describe Stack do
    before do
      @cli = prepare_command(Stack)
    end
    describe "index" do
      context "when --all is specified" do
        describe "heroku" do
          it "should receive list_stacks with show_deprecated = true" do
            @cli.stub(:options).and_return(:all => true)
            @cli.heroku.should_receive(:list_stacks).with('myapp', { :include_deprecated => true }).and_return([])
            @cli.index
          end
        end
      end
    end
  end
end
