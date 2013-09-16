require 'spec_helper'

describe 'users/edit.html.haml' do
  let(:user) { stub_model(User, :name => 'shingara') }
  before {
    view.stub(:current_user).and_return(user)
    view.stub(:user).and_return(user)
  }
  it 'should have per_page option' do
    render
    expect(rendered).to match(/id="user_per_page"/)
  end

  it 'should have time_zone option' do
    render
    expect(rendered).to match(/id="user_time_zone"/)
  end
end
