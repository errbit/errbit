require "spec_helper"
require "heroku/command/sharing"

module Heroku::Command
  describe Sharing do
    before do
      @cli = prepare_command(Sharing)
    end

    it "lists collaborators" do
      @cli.heroku.should_receive(:list_collaborators).and_return([])
      @cli.index
    end

    it "adds collaborators with default access to view only" do
      @cli.stub!(:args).and_return(['joe@example.com'])
      @cli.heroku.should_receive(:add_collaborator).with('myapp', 'joe@example.com')
      @cli.add
    end

    it "removes collaborators" do
      @cli.stub!(:args).and_return(['joe@example.com'])
      @cli.heroku.should_receive(:remove_collaborator).with('myapp', 'joe@example.com')
      @cli.remove
    end

    it "transfers ownership" do
      @cli.stub!(:args).and_return(['joe@example.com'])
      @cli.heroku.should_receive(:update).with('myapp', :transfer_owner => 'joe@example.com')
      @cli.transfer
    end
  end
end
