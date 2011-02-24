require 'spec_helper'

describe "errs/show.html.erb" do 
  before do 
    err = Factory(:err)
    assign :err, err
    assign :app, err.app
    assign :notices, err.notices.ordered.paginate(:page => 1, :per_page => 1)
    assign :notice, err.notices.first
  end

  describe "content_for :action_bar" do

    it "should confirm the 'resolve' link by default" do
      render 
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should =~ /data-confirm="Seriously\?"/
    end

    it "should confirm the 'resolve' link if configuration is unset" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(nil)
      render 
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should =~ /data-confirm="Seriously\?"/
    end

    it "should not confirm the 'resolve' link if configured not to" do
      Errbit::Config.stub(:confirm_resolve_err).and_return(false)
      render 
      action_bar = String.new(view.instance_variable_get(:@_content_for)[:action_bar])
      resolve_link = action_bar.match(/(<a href.*?(class="resolve").*?>)/)[0]
      resolve_link.should_not =~ /data-confirm=/
    end

  end

end
