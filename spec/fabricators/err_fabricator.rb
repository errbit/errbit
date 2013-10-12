Fabricator :err do
  problem
  fingerprint 'some-finger-print'
end

Fabricator :notice do
  err
  message             'FooError: Too Much Bar'
  backtrace
  server_environment  { {'environment-name' => 'production'} }
  request             {{ 'component' => 'foo', 'action' => 'bar' }}
  notifier            {{ 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' }}
end

Fabricator :backtrace do
  lines(:count => 99) { Fabricate.build(:backtrace_line) }
end

Fabricator :backtrace_line do
  number { rand(999) }
  file { "/path/to/file/#{SecureRandom.hex(4)}.rb" }
  method(:method) { ActiveSupport.methods.shuffle.first }
end

