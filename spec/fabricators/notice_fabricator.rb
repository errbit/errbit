Fabricator :notice do
  app
  err
  error_class 'FooError'
  message 'FooError: Too Much Bar'
  backtrace
  server_environment  { { 'environment-name' => 'production' } }
  request             { { 'component' => 'foo', 'action' => 'bar' } }
  notifier            { { 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' } }

  after_create do
    Problem.cache_notice(err.problem_id, self)
    problem.reload
  end
end
