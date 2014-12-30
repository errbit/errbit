Fabricator :issue_tracker do
  type_tracker 'mock'
  options {{
    :foo => 'one',
    :bar => 'two'
  }}
  app
end
