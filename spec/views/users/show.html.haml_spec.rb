describe 'users/show.html.haml', type: 'view' do
  let(:user) do
    stub_model(User, created_at: Time.zone.now, email: "test@example.com")
  end

  before do
    allow(Errbit::Config).to receive(:github_authentication).and_return(true)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:user).and_return(user)
  end

  context 'with GitHub authentication' do
    it 'shows github login' do
      user.github_login = 'test_user'
      render
      expect(rendered).to match(/GitHub/)
      expect(rendered).to match(/test_user/)
    end

    it 'does not show github if blank' do
      user.github_login = ' '
      render
      expect(rendered).to_not match(/GitHub/)
    end
  end

  context "Linking GitHub account" do
    context 'viewing another user page' do
      it "doesn't show and github linking buttons if user is not current user" do
        render
        expect(view.content_for(:action_bar)).to_not include('Link GitHub account')
        expect(view.content_for(:action_bar)).to_not include('Unlink GitHub account')
      end
    end

    context 'viewing own user page' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'shows link github button when no login or token' do
        render
        expect(view.content_for(:action_bar)).to include('Link GitHub account')
      end

      it 'shows unlink github button when login and token' do
        user.github_login = 'test_user'
        user.github_oauth_token = 'abcdef'

        render
        expect(view.content_for(:action_bar)).to include('Unlink GitHub account')
      end

      it "should confirm the 'resolve' link by default" do
        render
        expect(view.content_for(:action_bar)).to have_selector(
          format(
            'a.delete[data-confirm="%s"]',
            I18n.t('.users.confirm_delete')
          )
        )
      end
    end
  end
end
