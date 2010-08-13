require 'spec_helper'

describe UsersController do
  
  it_requires_authentication
  it_requires_admin
  
  context 'Signed in as an admin' do
    before do
      sign_in Factory(:admin)
    end

    context "GET /users" do
      it 'paginates all users' do
        users = 3.times.inject(WillPaginate::Collection.new(1,30)) {|page,_| page << Factory.build(:user)}
        User.should_receive(:paginate).and_return(users)
        get :index
        assigns(:users).should == users
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
          @user = Factory(:user)
          User.should_receive(:new).and_return(@user)
          @user.should_receive(:save).and_return(true)
        end
        
        it "sets a message to display" do
          post :create
          request.flash[:success].should include('part of the team')
        end
        
        it "redirects to the user's page" do
          post :create
          response.should redirect_to(user_path(@user))
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
        request.flash[:notice].should include('no longer part of your team')
      end
    end
    
  end
end
