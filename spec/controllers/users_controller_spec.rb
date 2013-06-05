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
      Time.zone.should.to_s == user.time_zone
    end

    context "GET /users/:other_id/edit" do
      it "redirects to the home page" do
        get :edit, :id => other_user.id
        response.should redirect_to(root_path)
      end
    end

    context "GET /users/:my_id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        controller.user.should == user
        expect(response).to render_template 'edit'
      end

    end

    context "PUT /users/:other_id" do
      it "redirects to the home page" do
        put :update, :id => other_user.id
        response.should redirect_to(root_path)
      end
    end

    context "PUT /users/:my_id/id" do
      context "when the update is successful" do
        it "sets a message to display" do
          put :update, :id => user.to_param, :user => {:name => 'Kermit'}
          request.flash[:success].should include('updated')
        end

        it "redirects to the user's page" do
          put :update, :id => user.to_param, :user => {:name => 'Kermit'}
          response.should redirect_to(user_path(user))
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
          user.reload.per_page.should == 555
        end

        it "should be able to set time_zone option" do
          put :update, :id => user.to_param, :user => {:time_zone => "Warsaw"}
          user.reload.time_zone.should == "Warsaw"
        end

        it "should be able to not set github_login option" do
          put :update, :id => user.to_param, :user => {:github_login => " "}
          user.reload.github_login.should == nil
        end

        it "should be able to set github_login option" do
          put :update, :id => user.to_param, :user => {:github_login => "awesome_name"}
          user.reload.github_login.should == "awesome_name"
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          put :update, :id => user.to_param, :user => {:name => nil}
          response.should render_template(:edit)
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
        controller.users.to_a.size.should == 2
      end

    end

    context "GET /users/:id" do
      it 'finds the user' do
        get :show, :id => user.id
        controller.user.should == user
      end
    end

    context "GET /users/new" do
      it 'assigns a new user' do
        get :new
        controller.user.should be_a(User)
        controller.user.should be_new_record
      end
    end

    context "GET /users/:id/edit" do
      it 'finds the user' do
        get :edit, :id => user.id
        controller.user.should == user
      end
    end

    context "POST /users" do
      context "when the create is successful" do
        let(:attrs) { {:user => Fabricate.attributes_for(:user)} }

        it "sets a message to display" do
          post :create, attrs
          request.flash[:success].should include('part of the team')
        end

        it "redirects to the user's page" do
          post :create, attrs
          response.should redirect_to(user_path(controller.user))
        end

        it "should be able to create admin" do
          attrs[:user][:admin] = true
          post :create, attrs
          response.should be_redirect
          User.find(controller.user.to_param).admin.should be_true
        end

        it "should has auth token" do
          post :create, attrs
          User.last.authentication_token.should_not be_blank
        end
      end

      context "when the create is unsuccessful" do
        let(:user) {
          Struct.new(:admin, :attributes).new(true, {})
        }
        before do
          User.should_receive(:new).and_return(user)
          user.should_receive(:save).and_return(false)
        end

        it "renders the new page" do
          post :create, :user => { :username => 'foo' }
          response.should render_template(:new)
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
          response.should render_template(:edit)
        end
      end
    end

    context "DELETE /users/:id" do

      context "with a destroy success" do
        let(:user_destroy) { mock(:destroy => true) }

        before {
          UserDestroy.should_receive(:new).with(user).and_return(user_destroy)
          delete :destroy, :id => user.id
        }

        it 'should destroy user' do
          expect(request.flash[:success]).to eq I18n.t('controllers.users.flash.destroy.success', :name => user.name)
          response.should redirect_to(users_path)
        end
      end

      context "with trying destroy himself" do
        before {
          UserDestroy.should_not_receive(:new)
          delete :destroy, :id => admin.id
        }

        it 'should not destroy user' do
          response.should redirect_to(users_path)
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
