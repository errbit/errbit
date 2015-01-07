require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rbenv' if ENV['rbenv']
require 'capistrano/bundler'
require 'capistrano/rails/assets'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
