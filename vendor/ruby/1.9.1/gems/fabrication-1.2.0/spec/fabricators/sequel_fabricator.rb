Fabricator(:parent_sequel_model) do
  dynamic_field { 'dynamic content' }
  nil_field nil
  number_field 5
  string_field 'content'
  after_create do |parent|
    2.times do
      Fabricate(:child_sequel_model, :parent => parent)
    end
  end
end

Fabricator(:child_sequel_model) do
  number_field 10
end
