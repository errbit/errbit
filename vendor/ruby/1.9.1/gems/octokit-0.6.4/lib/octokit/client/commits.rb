module Octokit
  class Client
    module Commits

      def commits(repo, branch="master", options={})
        get("/api/v2/json/commits/list/#{Repository.new(repo)}/#{branch}", options)['commits']
      end
      alias :list_commits :commits

      def commit(repo, sha, options={})
        get("/api/v2/json/commits/show/#{Repository.new(repo)}/#{sha}", options)['commit']
      end

    end
  end
end
