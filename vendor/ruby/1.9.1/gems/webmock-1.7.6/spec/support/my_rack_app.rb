require 'rack'

class MyRackApp
  def self.call(env)
    case env.values_at('REQUEST_METHOD', 'PATH_INFO')
      when ['GET', '/']
        [200, {}, ["This is my root!"]]
      when ['GET', '/greet']
        name = env['QUERY_STRING'][/name=([^&]*)/, 1] || "World"
        [200, {}, ["Hello, #{name}"]]
      when ['POST', '/greet']
        name = env["rack.input"].read[/name=([^&]*)/, 1] || "World"
        [200, {}, ["Good to meet you, #{name}!"]]
      else
        [404, {}, ['']]
    end
  end
end