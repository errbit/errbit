require 'graphql/client'
require 'graphql/client/http'

GITHUB_GRAPHQL_API_URL = Errbit::Config.github_api_url + '/graphql'
GITHUB_ACCESS_TOKEN = Errbit::Config.github_access_token

GraphQLHTTP = GraphQL::Client::HTTP.new(GITHUB_GRAPHQL_API_URL) do
  def headers(_context)
    { "Authorization": "Bearer #{GITHUB_ACCESS_TOKEN}" }
  end
end
Schema = GraphQL::Client.load_schema(GraphQLHTTP)
Client = GraphQL::Client.new(schema: Schema, execute: GraphQLHTTP)
Query = Client.parse <<-'GRAPHQL'
      query($name: String!, $owner: String!, $qualifiedName: String!, $path: String!) {
        repository(name: $name, owner: $owner) {
          ref(qualifiedName: $qualifiedName) {
            target {
              ... on Commit {
                blame(path: $path) {
                  ranges {
                    commit {
                      author {
                        name
                      }
                    }
                    startingLine
                    endingLine
                    age
                  }
                }
              }
            }
          }
        }
      }
GRAPHQL

class Blamer
  def self.blame_line(repo_name, repo_owner, branch, file_path, line_number)
    whodunnit = ''
    return whodunnit unless GITHUB_ACCESS_TOKEN.present?
    parsed_blame_hash = blame_file(repo_name, repo_owner, branch, file_path, parse_result: true)
    parsed_blame_hash.each do |range, author|
      range_array = range.split('-').map(&:to_i)
      if line_number.between?(range_array.first, range_array.second)
        whodunnit = author
      end
    end
    whodunnit
  end

  def self.blame_file(repo_name, repo_owner, branch, file_path, options = {})
    result = Client.query Query, variables: { name: repo_name, owner: repo_owner, qualifiedName: branch, path: file_path }
    if options[:parse_result] == true
      result = map_line_ranges_to_author(result)
    end
    result
  end

  def self.map_line_ranges_to_author(blame_object)
    new_blame_hash = {}
    blame_hash = blame_object.to_h
    blame_hash['data']['repository']['ref']['target']['blame']['ranges'].each do |commit_hash|
      new_blame_hash_key = "#{commit_hash['startingLine']}-#{commit_hash['endingLine']}"
      new_blame_hash[new_blame_hash_key] = commit_hash['commit']['author']['name']
    end
    new_blame_hash
  end
end
