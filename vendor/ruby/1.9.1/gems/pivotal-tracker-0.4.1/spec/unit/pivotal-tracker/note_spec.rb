require 'spec_helper'

describe PivotalTracker::Note do
  before do
    @project = PivotalTracker::Project.find(102622)
    @story = @project.stories.find(4460038)
  end

  context ".all" do
    it "should return an array of notes" do
      @story.notes.all.should be_a(Array)
      @story.notes.all.first.should be_a(PivotalTracker::Note)
    end
  end

  #context ".find" do
  #  it "should return a given task" do
  #    @story.tasks.find(179025).should be_a(PivotalTracker::Task)
  #  end
  #end

  context ".create" do
    it "should return the created note" do
      @story.notes.create(:text => 'Test note')
    end
  end

  context ".new" do

    def note_for(attrs)
      note = @story.notes.new(attrs)
      @note = Hash.from_xml(note.send(:to_xml))['note']
    end

    describe "attributes that are not sent to the tracker" do

      it "should include id" do
        note_for(:id => 10)["id"].should be_nil
      end

      it "should include author" do
        note_for(:author => "somebody")["author"].should be_nil
      end

    end

    describe "attributes that are sent to the tracker" do

      it "should include text" do
        note_for(:text => "A comment...")["text"].should == "A comment..."
      end

      it "should include noted_at" do
        note_for(:noted_at => "timestamp")["noted_at"].should == "timestamp"
      end

    end

  end

end
