set :stage, 'production'
server '127.0.0.1', user: 'haystak', roles: %w(web app db), port: 10022
set :deploy_to, '/var/projects/errbit'
