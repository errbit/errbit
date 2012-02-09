Fabricator(:parent_mongoid_document) do
  collection_field(:count => 2, :fabricator => :child_mongoid_document)
  dynamic_field { 'dynamic content' }
  nil_field nil
  number_field 5
  string_field 'content'
end

Fabricator(:child_mongoid_document) do
  number_field 10
end

# Mongoid Documents
Fabricator(:author) do
  name 'George Orwell'
  books(:count => 4) do |author, i|
    Fabricate.build(:book, :title => "book title #{i}", :author => author)
  end
end

Fabricator(:special_author, :from => :author) do
  mongoid_dynamic_field 50
  lazy_dynamic_field { "foo" }
end

Fabricator(:hemingway, :from => :author) do
  name 'Ernest Hemingway'
end

Fabricator(:book) do
  title "book title"
end

Fabricator(:publishing_house)
Fabricator(:book_promoter)
Fabricator(:professional_affiliation)
