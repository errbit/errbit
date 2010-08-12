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
    :params => {:id => 'dummyid'}
  }
  options.reverse_merge!(default_options)
  
  context 'when logged out' do
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