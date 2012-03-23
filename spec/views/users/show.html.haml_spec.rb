require 'spec_helper'

describe 'users/show.html.haml' do
  let(:user) do
    user = stub_model(User, :created_at => Time.now)
  end

  context 'with github auth' do
    before do
      Errbit::Config.stub(:github_authentication) { true }
    end

    it 'shows github login' do
      user.github_login = 'test_user'
      assign :user, user
      render
      rendered.should match(/GitHub/)
      rendered.should match(/test_user/)
    end

    it 'does not show github if blank' do
      user.github_login = ' '
      assign :user, user
      render
      rendered.should_not match(/GitHub/)
    end
  end
end
