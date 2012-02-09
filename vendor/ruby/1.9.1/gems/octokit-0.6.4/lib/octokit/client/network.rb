module Octokit
  class Client
    module Network
      def network_meta(repo, options={})
        get("/#{Repository.new(repo)}/network_meta", options, 2, false)
      end

      def network_data(repo, options={})
        get("/#{Repository.new(repo)}/network_data_chunk", options, 2, false)['commits']
      end
    end
  end
end
