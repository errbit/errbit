Fabricator :issue_tracker do
  type_tracker 'fake'
  options {{
    :foo => 'one',
    :bar => 'two'
  }}

  app
end
