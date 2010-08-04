Factory.sequence(:project_name) {|n| "Project ##{n}"}

Factory.define(:project) do |p|
  p.name { Factory.next :project_name }
end