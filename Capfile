require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rbenv' if ENV['rbenv']
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/puma'
require 'capistrano/rvm'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
