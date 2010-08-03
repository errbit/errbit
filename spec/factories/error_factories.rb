Factory.define :error do |e|
  e.klass         'FooError'
  e.message       'FooError: Too Much Bar'
  e.component     'foo'
  e.action        'bar'
  e.environment   'production'
end

Factory.define :notice do |n|
  n.error               {|e| e.association :error}
  n.backtrace           { random_backtrace }
  n.server_environment  'server-environment' => 'production'
  n.notifier            'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com'
end

def random_backtrace
  backtrace = []
  99.times {|t| backtrace << {
    'number'  => rand(999),
    'file'    => "/path/to/file/#{ActiveSupport::SecureRandom.hex(4)}.rb",
    'method'  => ActiveSupport.methods.shuffle.first
  }}
  backtrace
end