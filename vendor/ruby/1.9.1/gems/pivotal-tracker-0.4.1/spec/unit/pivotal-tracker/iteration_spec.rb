require 'spec_helper'

describe PivotalTracker::Iteration do
  before do
    @project = PivotalTracker::Project.find(PROJECT_ID)
  end

  describe ".all" do
    before do
      @iterations = PivotalTracker::Iteration.all(@project)
    end

    it "should return an array of Iterations for the given Project" do
      @iterations.should be_a(Array)
      @iterations.first.should be_a(PivotalTracker::Iteration)
    end
  end

  describe ".current" do
    before do
      @iteration = PivotalTracker::Iteration.current(@project)
    end

    it "should return a single Iteration" do
      @iteration.should be_a(PivotalTracker::Iteration)
    end
  end

  describe ".backlog" do
    before do
      @iterations = PivotalTracker::Iteration.backlog(@project)
    end

    it "should return an array of Iterations for the given Project" do
      @iterations.should be_a(Array)
      @iterations.first.should be_a(PivotalTracker::Iteration)
    end
  end

  describe ".done" do
    before do
      @iterations = PivotalTracker::Iteration.done(@project)
    end

    it "should return an array of Iterations for the given Project" do
      @iterations.should be_a(Array)
      @iterations.first.should be_a(PivotalTracker::Iteration)
    end
  end

end

