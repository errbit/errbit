require 'fabrication/cucumber'

World(FabricationMethods)

def with_ivars(fabricator)
  @they = yield fabricator
  instance_variable_set("@#{fabricator.model}", @they)
end

Given /^(\d+) ([^"]*)$/ do |count, model_name|
  with_ivars Fabrication::Cucumber::StepFabricator.new(model_name) do |fab|
    fab.n(count.to_i)
  end
end

Given /^the following ([^"]*):$/ do |model_name, table|
  with_ivars Fabrication::Cucumber::StepFabricator.new(model_name) do |fab|
    fab.from_table(table)
  end
end

Given /^that ([^"]*) has the following ([^"]*):$/ do |parent, child, table|
  with_ivars Fabrication::Cucumber::StepFabricator.new(child, :parent => parent) do |fab|
    fab.from_table(table)
  end
end

Given /^that ([^"]*) has (\d+) ([^"]*)$/ do |parent, count, child|
  with_ivars Fabrication::Cucumber::StepFabricator.new(child, :parent => parent) do |fab|
    fab.n(count.to_i)
  end
end

Given /^(?:that|those) (.*) belongs? to that (.*)$/ do |children, parent|
  with_ivars Fabrication::Cucumber::StepFabricator.new(parent) do |fab|
    fab.has_many(children)
  end
end

Then /^I should see (\d+) ([^"]*) in the database$/ do |count, model_name|
  Fabrication::Cucumber::StepFabricator.new(model_name).klass.count.should == count.to_i
end

Then /^I should see the following (.*) in the database:$/ do |model_name, table|
  klass = Fabrication::Cucumber::StepFabricator.new(model_name).klass
  klass.where(table.rows_hash).count.should == 1
end
