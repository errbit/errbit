Factory.define :problem do |p|
  p.app            {|a| a.association :app}
end

Factory.define :err do |e|
  e.problem        {|p| p.association :problem}
  e.klass         'FooError'
  e.component     'foo'
  e.action        'bar'
  e.environment   'production'
end

Factory.define :notice do |n|
  n.err                 {|e| e.association :err}
  n.message             'FooError: Too Much Bar'
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