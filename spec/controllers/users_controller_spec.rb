require 'spec_helper'

describe UsersController do

  it_requires_authentication
  it_requires_admin_privileges :for => {
    :index    => :get,
    :show     => :get,
    :new      => :get,
    :create   => :post,
    :destroy  => :delete
  }

  let(:admin) { Fabricate(:admin) }
  let(:user) { Fabricate(:user) }
  let(:other_user) { Fabricate(:user) }

  context 'Signed in as a regular user' do

    before do
      sign_in user
    end

    it "should set a time zone" do
      expect(Time.zone.to_s).to match(user.time_zone)
    end

    context "GET /users/:other_id/edit" do
      it "redirects to the home page" do
        get :edit, :id => other_user.id
        expect(response).to redirect_to(root_path)
      end
    end

    context "GET /users/:my_id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        expect(controller.user).to eq user
        expect(response).to render_template 'edit'
      end

    end

    context "PUT /users/:other_id" do
      it "redirects to the home page" do
        put :update, :id => other_user.id
        expect(response).to redirect_to(root_path)
      end
    end

    context "PUT /users/:my_id/id" do
      context "when the update is successful" do
        it "sets a message to display" do
          put :update, :id => user.to_param, :user => {:name => 'Kermit'}
          expect(request.flash[:success]).to include('updated')
        end

        it "redirects to the user's page" do
          put :update, :id => user.to_param, :user => {:name => 'Kermit'}
          expect(response).to redirect_to(user_path(user))
        end

        it "should not be able to become an admin" do
          expect {
            put :update, :id => user.to_param, :user => {:admin => true}
          }.to_not change {
            user.reload.admin
          }.from(false)
        end

        it "should be able to set per_page option" do
          put :update, :id => user.to_param, :user => {:per_page => 555}
          expect(user.reload.per_page).to eq 555
        end

        it "should be able to set time_zone option" do
          put :update, :id => user.to_param, :user => {:time_zone => "Warsaw"}
          expect(user.reload.time_zone).to eq "Warsaw"
        end

        it "should be able to not set github_login option" do
          put :update, :id => user.to_param, :user => {:github_login => " "}
          expect(user.reload.github_login).to eq nil
        end

        it "should be able to set github_login option" do
          put :update, :id => user.to_param, :user => {:github_login => "awesome_name"}
          expect(user.reload.github_login).to eq "awesome_name"
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          put :update, :id => user.to_param, :user => {:name => nil}
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  context 'Signed in as an admin' do
    before do
      sign_in admin
    end

    context "GET /users" do

      it 'paginates all users' do
        admin.update_attribute :per_page, 2
        users = 3.times {
          Fabricate(:user)
        }
        get :index
        expect(controller.users.to_a.size).to eq 2
      end

    end

    context "GET /users/:id" do
      it 'finds the user' do
        get :show, :id => user.id
        expect(controller.user).to eq user
      end
    end

    context "GET /users/new" do
      it 'assigns a new user' do
        get :new
        expect(controller.user).to be_a(User)
        expect(controller.user).to be_new_record
      end
    end

    context "GET /users/:id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        expect(controller.user).to eq user
      end
    end

    context "POST /users" do
      context "when the create is successful" do
        let(:attrs) { {:user => Fabricate.attributes_for(:user)} }

        it "sets a message to display" do
          post :create, attrs
          expect(request.flash[:success]).to include('part of the team')
        end

        it "redirects to the user's page" do
          post :create, attrs
          expect(response).to redirect_to(user_path(controller.user))
        end

        it "should be able to create admin" do
          attrs[:user][:admin] = true
          post :create, attrs
          expect(response).to be_redirect
          expect(User.find(controller.user.to_param).admin).to be_true
        end

        it "should has auth token" do
          post :create, attrs
          expect(User.last.authentication_token).to_not be_blank
        end
      end

      context "when the create is unsuccessful" do
        let(:user) {
          Struct.new(:admin, :attributes).new(true, {})
        }
        before do
          expect(User).to receive(:new).and_return(user)
          expect(user).to receive(:save).and_return(false)
        end

        it "renders the new page" do
          post :create, :user => { :username => 'foo' }
          expect(response).to render_template(:new)
        end
      end
    end

    context "PUT /users/:id" do
      context "when the update is successful" do
        before {
          put :update, :id => user.to_param, :user => user_params
        }

        context "with normal params" do
          let(:user_params) { {:name => 'Kermit'} }
          it "sets a message to display" do
            expect(request.flash[:success]).to eq I18n.t('controllers.users.flash.update.success', :name => user.name)
            expect(response).to redirect_to(user_path(user))
          end
        end
      end
      context "when the update is unsuccessful" do

        it "renders the edit page" do
          put :update, :id => user.to_param, :user => {:name => nil}
          expect(response).to render_template(:edit)
        end
      end
    end

    context "DELETE /users/:id" do

      context "with a destroy success" do
        let(:user_destroy) { double(:destroy => true) }

        before {
          expect(UserDestroy).to receive(:new).with(user).and_return(user_destroy)
          delete :destroy, :id => user.id
        }

        it 'should destroy user' do
          expect(request.flash[:success]).to eq I18n.t('controllers.users.flash.destroy.success', :name => user.name)
          expect(response).to redirect_to(users_path)
        end
      end

      context "with trying destroy himself" do
        before {
          expect(UserDestroy).to_not receive(:new)
          delete :destroy, :id => admin.id
        }

        it 'should not destroy user' do
          expect(response).to redirect_to(users_path)
          expect(request.flash[:error]).to eq I18n.t('controllers.users.flash.destroy.error')
        end
      end
    end

    describe "#user_params" do
      context "with current user not admin" do
        before {
          controller.stub(:current_user).and_return(user)
          controller.stub(:params).and_return(ActionController::Parameters.new(user_param))
        }
        let(:user_param) { {'user' => { :name => 'foo', :admin => true }} }
        it 'not have admin field' do
          expect(controller.send(:user_params)).to eq ({'name' => 'foo'})
        end
        context "with password and password_confirmation empty?" do
          let(:user_param) { {'user' => { :name => 'foo', 'password' => '', 'password_confirmation' => '' }} }
          it 'not have password and password_confirmation field' do
            expect(controller.send(:user_params)).to eq ({'name' => 'foo'})
          end
        end
      end

      context "with current user admin" do
        it 'have admin field'
        context "with password and password_confirmation empty?" do
          it 'not have password and password_confirmation field'
        end
        context "on his own user" do
          it 'not have admin field'
        end
      end
    end

  end

end
