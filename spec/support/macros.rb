def it_requires_authentication(options = {})
  default_options = {
    :for => {
      :index    => :get,
      :show     => :get,
      :new      => :get,
      :create   => :post,
      :edit     => :get,
      :update   => :put,
      :destroy  => :delete
    },
    :params => {:id => '4c6c760494df2a18cc000015'}
  }
  options.reverse_merge!(default_options)

  context 'when signed out' do
    before do
      sign_out :user
    end

    options[:for].each do |action, method|
      it "#{method.to_s.upcase} #{action} redirects to the sign in page" do
        send(method, action, options[:params])
        response.should redirect_to(new_user_session_path)
      end
    end
  end
end

def  it_requires_admin_privileges(options = {})
  default_options = {
    :for => {
      :index    => :get,
      :show     => :get,
      :new      => :get,
      :create   => :post,
      :edit     => :get,
      :update   => :put,
      :destroy  => :delete
    },
    :params => {:id => 'dummyid'}
  }
  options.reverse_merge!(default_options)

  context 'when signed in as a regular user' do
    before do
      sign_out :user
      sign_in Factory(:user)
    end

    options[:for].each do |action, method|
      it "#{method.to_s.upcase} #{action} redirects to the root path" do
        send(method, action, options[:params])
        response.should redirect_to(root_path)
      end
    end
  end
end