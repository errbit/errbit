require 'spec_helper'

describe UserDestroy do
  let(:app) { Fabricate(
    :app,
    :watchers => [
      Fabricate.build(:user_watcher, :user => user)
    ])
  }

  describe "#destroy" do
    let!(:user) { Fabricate(:user) }
    it 'should delete user' do
      expect {
        UserDestroy.new(user).destroy
      }.to change(User, :count)
    end

    it 'should delete watcher' do
      expect {
        UserDestroy.new(user).destroy
      }.to change{
        app.reload.watchers.where(:user_id => user.id).count
      }.from(1).to(0)
    end
  end
end
