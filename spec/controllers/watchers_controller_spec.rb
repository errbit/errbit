require 'spec_helper'

describe WatchersController, type: 'controller' do
  let(:app) do
    a = Fabricate(:app)
    Fabricate(:user_watcher, :app => a)
    a
  end

  describe "PUT /apps/:app_id/watchers/:id" do
    context "with ordinary user" do
      let(:user) { Fabricate(:user) }

      before :each do
        sign_in user
      end

      it "should create a watcher for the user" do
        put :update, :app_id => app.id, :id => user.id

        expect(app.reload.watchers.where(:user_id => user.id)).not_to be_empty
      end

      it "should redirect to the app path" do
        put :update, :app_id => app.id, :id => user.id

        expect(response).to redirect_to(app_path(app))
      end

      it "should just redirect if a watcher already exists for the user" do
        Fabricate(:user_watcher, :app => app, :user => user)
        expect {
          put :update, :app_id => app.id, :id => user.id.to_s
        }.not_to change { app.reload.watchers.count }

        expect(response).to redirect_to(app_path(app))
      end

      it "should not create a watcher for another user" do
        user2 = Fabricate(:user)

        expect {
          put :update, :app_id => app.id, :id => user2.id
        }.not_to change { app.reload.watchers.count }
      end
    end
  end

  describe "DELETE /apps/:app_id/watchers/:id/destroy" do
    context "with admin user" do
      before(:each) do
        sign_in Fabricate(:admin)
      end

      context "successful watcher deletion" do
        let(:problem) { Fabricate(:problem_with_comments) }
        let(:watcher) { Fabricate(:user_watcher, :app => app) }

        before(:each) do
          delete :destroy, :app_id => app.id, :id => watcher.user.id.to_s
          problem.reload
        end

        it "should delete the watcher" do
          expect(app.watchers.detect{|w| w.id.to_s == watcher.id }).to be nil
        end

        it "should redirect to app page" do
          expect(response).to redirect_to(app_path(app))
        end
      end
    end
  end
end
