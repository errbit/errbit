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

  after_create do
    Problem.cache_notice(err.problem_id, self)
    problem.reload
  end
end

Fabricator :backtrace do
  lines(:count => 99) do
    {
      number: rand(999),
      file: "/path/to/file/#{SecureRandom.hex(4)}.rb",
      method: ActiveSupport.methods.shuffle.first
    }
  end
end
