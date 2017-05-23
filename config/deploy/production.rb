set :stage, 'production'
server 'errbit.hs.stackbuilders.net', user: 'haystak', roles: %w(web app db)
set :deploy_to, '/var/projects/errbit'
