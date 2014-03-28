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
