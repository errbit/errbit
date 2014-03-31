Fabricator :filter do
  description 'Kill those annoying FooBar exceptions.'
  message 'Foo'
  error_class 'FooBar'
  url 'example\.com'
  where 'test'
end

Fabricator :empty_filter, :from => :filter do
  description 'Kill those annoying FooBar exceptions.'
  message 'some message'
  error_class ''
  url ''
  where ''
end

Fabricator :foobar_notice, :from => :notice do
  message             'FooError: Too Much Bar'
  server_environment  { {'environment-name' => 'production'} }
  request             {{ 'component' => 'foo', 'action' => 'bar' }}
  notifier            {{ 'name' => 'Notifier', 'version' => '1', 'url' => 'http://toad.com' }}
end
