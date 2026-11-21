# frozen_string_literal: true

require "rails_helper"

RSpec.describe Problem, type: :model do
  context "when destroying with dependencies" do
    let(:problem) do
      problem = Problem.new
      allow(problem).to receive(:errs).and_return(double(:criteria, pluck: [err_1.id, err_2.id]))
      allow(problem).to receive(:comments).and_return(double(:criteria, pluck: [comment_1.id, comment_2.id]))
      allow(problem).to receive(:delete)
      problem
    end
    let(:err_1) { Err.new }
    let(:err_2) { Err.new }

    let(:comment_1) { Comment.new }
    let(:comment_2) { Comment.new }

    describe "#destroy_with_dependencies" do
      it "destroy the problem himself" do
        expect(problem).to receive(:delete).and_return(true)
        problem.destroy_with_dependencies
      end

      it "delete all errs associate" do
        expect(Err).to receive(:delete_all).with(_id: {"$in" => [err_1.id, err_2.id]})
        problem.destroy_with_dependencies
      end

      it "delete all comments associate" do
        expect(Comment).to receive(:delete_all).with(_id: {"$in" => [comment_1.id, comment_2.id]})
        problem.destroy_with_dependencies
      end

      it "delete all notice of associate to this errs" do
        expect(Notice).to receive(:delete_all).with(err_id: {"$in" => [err_1.id, err_2.id]})
        problem.destroy_with_dependencies
      end
    end
  end

  context "when destroying with dependencies in the database" do
    let!(:problem) { create(:problem) }
    let!(:comment_1) { create(:comment, err: problem) }
    let!(:comment_2) { create(:comment, err: problem) }
    let!(:err_1) { create(:err, problem: problem) }
    let!(:err_2) { create(:err, problem: problem) }
    let!(:notice_1_1) { create(:notice, err: err_1) }
    let!(:notice_1_2) { create(:notice, err: err_1) }
    let!(:notice_2_1) { create(:notice, err: err_2) }
    let!(:notice_2_2) { create(:notice, err: err_2) }

    it "should all destroy" do
      problem.destroy_with_dependencies
      expect(Problem.where(_id: problem.id).entries).to be_empty
      expect(Err.where(_id: err_1.id).entries).to be_empty
      expect(Err.where(_id: err_2.id).entries).to be_empty
      expect(Comment.where(_id: comment_1.id).entries).to be_empty
      expect(Comment.where(_id: comment_2.id).entries).to be_empty
      expect(Notice.where(_id: notice_1_1.id).entries).to be_empty
      expect(Notice.where(_id: notice_1_2.id).entries).to be_empty
      expect(Notice.where(_id: notice_2_1.id).entries).to be_empty
      expect(Notice.where(_id: notice_2_2.id).entries).to be_empty
    end
  end
end
