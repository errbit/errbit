Fabricator :err do
  problem!
  klass!         { 'FooError' }
  component     'foo'
  action        'bar'
  environment   'production'
end

Fabricator :notice do
  err!
  message             'FooError: Too Much Bar'
  backtrace           { random_backtrace }
  server_environment  { {'environment-name' => 'production'} }
  request             {{ 'component' => 'foo', 'action' => 'bar' }}
  notifier            {{ 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' }}
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

