require 'spec_helper'

describe WatchersController do
  let(:app) { Fabricate(:app_with_watcher) }

  describe "DELETE /apps/:app_id/watchers/:id/destroy" do
    render_views

    before(:each) do
      sign_in Fabricate(:admin)
    end

    context "successful comment deletion" do
      let(:problem) { Fabricate(:problem_with_comments) }
      let(:watcher) { app.watchers.first }

      before(:each) do
        delete :destroy, :app_id => app.id, :id => watcher.id.to_s
        problem.reload
      end

      it "should delete the watcher" do
        app.watchers.detect{|w| w.id.to_s == watcher.id }.should == nil
      end

      it "should redirect to index page" do
        response.should redirect_to(root_path)
      end
    end
  end
end
