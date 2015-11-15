Fabricator :issue_tracker do
  type_tracker 'mock'
  options do
    {
      foo: 'one',
      bar: 'two'
    }
  end
  app
end
