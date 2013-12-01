require 'spec_helper'

describe WatchersController do
  let(:app) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :app => a)
    a
  end

  describe "DELETE /apps/:app_id/watchers/:id/destroy" do

    context "with admin user" do
      before(:each) do
        sign_in Fabricate(:admin)
      end

      context "successful watcher deletion" do
        let(:problem) { Fabricate(:problem_with_comments) }
        let(:watcher) { app.watchers.first }

        before(:each) do
          delete :destroy, :app_id => app.id, :id => watcher.user.id.to_s
          problem.reload
        end

        it "should delete the watcher" do
          expect(app.watchers.detect{|w| w.id.to_s == watcher.id }).to be nil
        end

        it "should redirect to index page" do
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
