Fabricator :filter do
  message 'Foo'
  error_class 'FooBar'
  url 'example\.com'
  where 'test'
end

Fabricator :empty_filter, :from => :filter do
  message 'some message'
  error_class ''
  url ''
  where ''
end
