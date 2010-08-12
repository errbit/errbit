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
  end
end
