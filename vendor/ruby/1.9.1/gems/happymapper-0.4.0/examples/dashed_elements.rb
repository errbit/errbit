dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/commit.xml')

module GitHub
  class Commit
    include HappyMapper

    tag "commit"
    element :url, String
    element :tree, String
    element :message, String
    element :id, String
    element :'committed-date', Date
  end
end

commit = GitHub::Commit.parse(file_contents)
puts commit.committed_date, commit.url, commit.id