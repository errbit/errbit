require 'ostruct'

module HttpRequestTestHelper
  def http_request(method, uri, options = {})
    begin
      uri = URI.parse(uri)
    rescue
      uri = Addressable::URI.heuristic_parse(uri)
    end
    response = nil
    clazz = ::Net::HTTP.const_get("#{method.to_s.capitalize}")
    req = clazz.new("#{uri.path}#{uri.query ? '?' : ''}#{uri.query}", options[:headers])
    req.basic_auth uri.user, uri.password if uri.user
    http = ::Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    response = http.start {|http|
      http.request(req, options[:body])
    }
    OpenStruct.new({
      :body => response.body,
      :headers => response,
      :status => response.code })
  end
end