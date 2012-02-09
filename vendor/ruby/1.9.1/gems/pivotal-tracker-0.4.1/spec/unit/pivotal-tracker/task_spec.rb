require 'spec_helper'

describe PivotalTracker::Task do
  before do
    @project = PivotalTracker::Project.find(102622)
    @story = @project.stories.find(4459994)
  end

  context ".all" do
    it "should return an array of tasks" do
      @story.tasks.all.should be_a(Array)
      @story.tasks.all.first.should be_a(PivotalTracker::Task)
    end
  end

  context ".find" do
    it "should return a given task" do
      @story.tasks.find(468113).should be_a(PivotalTracker::Task)
    end
  end
end
