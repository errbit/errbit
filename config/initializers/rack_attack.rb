Rails.application.configure do |config|
  config.middleware.use Rack::Attack unless (Rails.env.test? || Rails.env.development?)
end

Rack::Attack.blocklist('block all but VPN ips') do |req|
  vpn_ips = ['136.244.114.222']
  !(req.path =~ /\A\/api/) && !vpn_ips.include?(req.ip)
end

if ENV['BLOCKED_IPS'].present?
  ENV['BLOCKED_IPS'].split(",").each do |ip|
    Rack::Attack.blocklist_ip(ip)
  end
end

Rack::Attack.blocklisted_response = lambda do |env|
  [ 404, {}, [File.open(Rails.root.join("public/404.html")).read]]
end
