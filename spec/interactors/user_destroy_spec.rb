describe UserDestroy do
  let(:app) do
    Fabricate(
      :app,
      watchers: [
        Fabricate.build(:user_watcher, user: user)
      ])
  end

  describe "#destroy" do
    let!(:user) { Fabricate(:user) }
    it "should delete user" do
      expect do
        UserDestroy.new(user).destroy
      end.to change(User, :count)
    end

    it "should delete watcher" do
      expect do
        UserDestroy.new(user).destroy
      end.to change {
        app.reload.watchers.where(user_id: user.id).count
      }.from(1).to(0)
    end
  end
end
