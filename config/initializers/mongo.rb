require 'uri'

Mongoid.configure do |config|
  uri = URI.parse(Errbit::Config.mongo_url)

  params = {
    hosts: [ uri.port ? sprintf("%s:%s", uri.host, uri.port) : uri.host ]
  }

  params[:username] = uri.user if uri.user
  params[:password] = uri.password if uri.password

  if uri.path.empty?
    params[:database] = "errbit_#{Rails.env}"
  else
    params[:database] = uri.path.sub(/^\//, '')
  end

  config.load_configuration({
    sessions: {
      default: params
    }
  })
end

Mongoid.use_activesupport_time_zone = true
