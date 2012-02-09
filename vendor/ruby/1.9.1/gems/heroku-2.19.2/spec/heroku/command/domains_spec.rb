require "spec_helper"
require "heroku/command/domains"

module Heroku::Command
  describe Domains do
    before do
      @domains = prepare_command(Domains)
      @domains.heroku.stub!(:info).and_return({})
    end

    it "lists domains" do
      @domains.heroku.should_receive(:list_domains).and_return([])
      @domains.index
    end

    it "adds domain names" do
      @domains.stub!(:args).and_return(['example.com'])
      @domains.heroku.should_receive(:add_domain).with('myapp', 'example.com')
      @domains.add
    end

    it "shows usage if no domain specified for add" do
      @domains.stub!(:args).and_return([])
      lambda { @domains.add }.should raise_error(CommandFailed, /Usage:/)
    end

    it "shows usage if blank domain specified for add" do
      @domains.stub!(:args).and_return(['  '])
      lambda { @domains.add }.should raise_error(CommandFailed, /Usage:/)
    end

    it "removes domain names" do
      @domains.stub!(:args).and_return(['example.com'])
      @domains.heroku.should_receive(:remove_domain).with('myapp', 'example.com')
      @domains.remove
    end

    it "shows usage if no domain specified for remove" do
      @domains.stub!(:args).and_return([])
      lambda { @domains.remove }.should raise_error(CommandFailed, /Usage:/)
    end

    it "shows usage if blank domain specified for remove" do
      @domains.stub!(:args).and_return(['  '])
      lambda { @domains.remove }.should raise_error(CommandFailed, /Usage:/)
    end

    it "removes all domain names" do
      @domains.heroku.should_receive(:remove_domains).with('myapp')
      @domains.clear
    end
  end
end
