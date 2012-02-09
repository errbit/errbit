Fabricator(:parent_active_record_model) do
  collection_field(:count => 2, :fabricator => :child_active_record_model)
  dynamic_field { 'dynamic content' }
  nil_field nil
  number_field 5
  string_field 'content'
end

Fabricator(:child_active_record_model) do
  number_field 10
end

# ActiveRecord Objects
Fabricator(:division) do
  name "Division Name"
end

Fabricator(:squadron, :from => :division)

Fabricator(:company)
Fabricator(:startup, :from => :company)
