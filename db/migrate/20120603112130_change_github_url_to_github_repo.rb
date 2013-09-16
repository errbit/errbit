class ChangeGithubUrlToGithubRepo < Mongoid::Migration
  def self.up
    App.collection.find.update({'$rename' => {'github_url' => 'github_repo'}}, :multi => true, :safe => true)
    App.all.each do |app|
      app.send :normalize_github_repo
      app.save
    end
  end

  def self.down
    App.collection.find.update({'$rename' => {'github_repo' => 'github_url'}}, :multi => true, :safe => true)
    App.all.each do |app|
      unless app.github_repo.include?("github.com")
        app.update_attribute :github_url, "https://github.com/" << app.github_url
      end
    end
  end
end
