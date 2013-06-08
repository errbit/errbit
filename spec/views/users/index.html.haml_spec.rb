require 'spec_helper'

describe 'users/index.html.haml' do
  let(:user) { stub_model(User) }
  before {
    view.stub(:current_user).and_return(user)
    view.stub(:users).and_return(
      Kaminari.paginate_array([user], :total_count => 1).page(1)
    )
  }
  it 'should see users option' do
    render
    expect(rendered).to match(/class='user_list'/)
  end

end
