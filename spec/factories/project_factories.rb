Factory.sequence(:project_name) {|n| "Project ##{n}"}
Factory.sequence(:email) {|n| "email#{n}@example.com"}

Factory.define(:project) do |p|
  p.name { Factory.next :project_name }
end

Factory.define(:watcher) do |w|
  w.project {|p| p.association :project}
  w.email   { Factory.next :email }
end