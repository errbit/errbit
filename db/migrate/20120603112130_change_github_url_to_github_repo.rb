class ChangeGithubUrlToGithubRepo < Mongoid::Migration
  def self.normalize_github_repo(repo)
    return if repo.blank?
    github_host = URI.parse(Errbit::Config.github_url).host
    github_host = Regexp.escape(github_host)
    repo.strip!
    repo.sub!(/(git@|https?:\/\/)#{github_host}(\/|:)/, '')
    repo.sub!(/\.git$/, '')
    repo
  end

  def self.up
    App.collection.find.update({'$rename' => {'github_url' => 'github_repo'}}, :multi => true, :safe => true)
    App.all.each do |app|
      normalized_repo = self.normalize_github_repo(app.attributes['github_repo'])
      App.collection.where({ _id: app.id }).update({
        "$set" => { :github_repo =>  normalized_repo }
      })
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
