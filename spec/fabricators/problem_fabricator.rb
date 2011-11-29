Fabricator(:problem) do
  app!
  comments      []
end

Fabricator(:problem_with_comments, :from => :problem) do
  comments(:count => 3) { |parent, i| Fabricate(:comment, :err => parent) }
end
