require 'ostruct'

module TyphoeusHydraSpecHelper
  class FakeTyphoeusHydraError < StandardError; end


  def http_request(method, uri, options = {}, &block)
    uri.gsub!(" ", "%20") #typhoeus doesn't like spaces in the uri
    response = Typhoeus::Request.run(uri,
      {
        :method  => method,
        :body    => options[:body],
        :headers => options[:headers],
        :timeout => 15000 # milliseconds
      }
    )
    raise FakeTyphoeusHydraError.new if response.code.to_s == "0"
    OpenStruct.new({
      :body => response.body,
      :headers => WebMock::Util::Headers.normalize_headers(join_array_values(response.headers_hash)),
      :status => response.code.to_s,
      :message => response.status_message
    })
  end

  def join_array_values(hash)
    joined = {}
    if hash
     hash.each do |k,v|
       v = v.join(", ") if v.is_a?(Array)
       joined[k] = v
     end
    end
    joined
  end


  def client_timeout_exception_class
    FakeTyphoeusHydraError
  end

  def connection_refused_exception_class
    FakeTyphoeusHydraError
  end

  def http_library
    :typhoeus
  end

end
