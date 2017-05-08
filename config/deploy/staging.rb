
server 'ec2-54-71-211-16.us-west-2.compute.amazonaws.com', user: 'ubuntu', roles: %w(web app db)

set :ssh_options, {
  keys: %w(~/.pem/cognoa-oregon-staging-ops.pem),
  forward_agent: false,
  auth_methods: %w(publickey)
}
