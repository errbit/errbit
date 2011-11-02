require 'spec_helper'

describe UsersController do
  render_views

  it_requires_authentication
  it_requires_admin_privileges :for => {
    :index    => :get,
    :show     => :get,
    :new      => :get,
    :create   => :post,
    :destroy  => :delete
  }

  context 'Signed in as a regular user' do
    before do
      sign_in @user = Factory(:user)
    end
    
    it "should set a time zone" do
      Time.zone.should.to_s == @user.time_zone
    end

    context "GET /users/:other_id/edit" do
      it "redirects to the home page" do
        get :edit, :id => Factory(:user).id
        response.should redirect_to(root_path)
      end
    end

    context "GET /users/:my_id/edit" do
      it 'finds the user' do
        get :edit, :id => @user.id
        assigns(:user).should == @user
      end

      it "should have per_page option" do
        get :edit, :id => @user.id
        response.body.should match(/id="user_per_page"/)
      end

      it "should have time_zone option" do
        get :edit, :id => @user.id
        response.body.should match(/id="user_time_zone"/)
      end
    end

    context "PUT /users/:other_id" do
      it "redirects to the home page" do
        put :update, :id => Factory(:user).id
        response.should redirect_to(root_path)
      end
    end

    context "PUT /users/:my_id/id" do
      context "when the update is successful" do
        it "sets a message to display" do
          put :update, :id => @user.to_param, :user => {:name => 'Kermit'}
          request.flash[:success].should include('updated')
        end

        it "redirects to the user's page" do
          put :update, :id => @user.to_param, :user => {:name => 'Kermit'}
          response.should redirect_to(user_path(@user))
        end

        it "should not be able to become an admin" do
          put :update, :id => @user.to_param, :user => {:admin => true}
          @user.reload.admin.should be_false
        end

        it "should be able to set per_page option" do
          put :update, :id => @user.to_param, :user => {:per_page => 555}
          @user.reload.per_page.should == 555
        end
        
        it "should be able to set time_zone option" do
          put :update, :id => @user.to_param, :user => {:time_zone => "Warsaw"}
          @user.reload.time_zone.should == "Warsaw"
        end
      end

      context "when the update is unsuccessful" do
        it "renders the edit page" do
          put :update, :id => @user.to_param, :user => {:name => nil}
          response.should render_template(:edit)
        end
      end
    end
  end

  context 'Signed in as an admin' do
    before do
      @user = Factory(:admin)
      sign_in @user
    end

    context "GET /users" do
      it 'paginates all users' do
        @user.update_attribute :per_page, 2
        users = 3.times { Factory(:user) }
        get :index
        assigns(:users).to_a.size.should == 2
      end
    end

    context "GET /users/:id" do
      it 'finds the user' do
        user = Factory(:user)
        get :show, :id => user.id
        assigns(:user).should == user
      end
    end

    context "GET /users/new" do
      it 'assigns a new user' do
        get :new
        assigns(:user).should be_a(User)
        assigns(:user).should be_new_record
      end
    end

    context "GET /users/:id/edit" do
      it 'finds the user' do
        user = Factory(:user)
        get :edit, :id => user.id
        assigns(:user).should == user
      end
    end

    context "POST /users" do
      context "when the create is successful" do
        before do
          @attrs = {:user => Factory.attributes_for(:user)}
        end

        it "sets a message to display" do
          post :create, @attrs
          request.flash[:success].should include('part of the team')
        end

        it "redirects to the user's page" do
          post :create, @attrs
          response.should redirect_to(user_path(assigns(:user)))
        end

        it "should be able to create admin" do
          @attrs[:user][:admin] = true
          post :create, @attrs
          response.should be_redirect
          User.find(assigns(:user).to_param).admin.should be_true
        end

        it "should has auth token" do
          post :create, @attrs
          User.last.authentication_token.should_not be_blank
        end
      end

      context "when the create is unsuccessful" do
        before do
          @user = Factory(:user)
          User.should_receive(:new).and_return(@user)
          @user.should_receive(:save).and_return(false)
        end

        it "renders the new page" do
          post :create
          response.should render_template(:new)
        end
      end
    end

    context "PUT /users/:id" do
      context "when the update is successful" do
        before do
          @user = Factory(:user)
        end

        it "sets a message to display" do
          put :update, :id => @user.to_param, :user => {:name => 'Kermit'}
          request.flash[:success].should include('updated')
        end

        it "redirects to the user's page" do
          put :update, :id => @user.to_param, :user => {:name => 'Kermit'}
          response.should redirect_to(user_path(@user))
        end

        it "should be able to make user an admin" do
          put :update, :id => @user.to_param, :user => {:admin => true}
          response.should be_redirect
          User.find(assigns(:user).to_param).admin.should be_true
        end
      end

      context "when the update is unsuccessful" do
        before do
          @user = Factory(:user)
        end

        it "renders the edit page" do
          put :update, :id => @user.to_param, :user => {:name => nil}
          response.should render_template(:edit)
        end
      end
    end

    context "DELETE /users/:id" do
      before do
        @user = Factory(:user)
      end

      it "destroys the user" do
        delete :destroy, :id => @user.id
        User.where(:id => @user.id).first.should be_nil
      end

      it "redirects to the users index page" do
        delete :destroy, :id => @user.id
        response.should redirect_to(users_path)
      end

      it "sets a message to display" do
        delete :destroy, :id => @user.id
        request.flash[:success].should include('no longer part of your team')
      end
    end

  end
end

