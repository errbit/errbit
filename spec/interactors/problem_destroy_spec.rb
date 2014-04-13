require 'spec_helper'

describe ProblemDestroy do
  let(:problem_destroy) {
    ProblemDestroy.new(problem)
  }

  context "in unit way" do
    let(:problem) {
      problem = Problem.new
      problem.stub(:errs).and_return([err_1, err_2].tap { |arr| arr.stub(:pluck).and_return([err_1.id, err_2.id]) })
      problem.stub(:comments).and_return([comment_1, comment_2].tap { |arr| arr.stub(:pluck).and_return([comment_1.id, comment_2.id]) })
      problem.stub(:delete)
      problem
    }
    let(:err_1) { Fabricate(:err) }
    let(:err_2) { Fabricate(:err) }

    let(:comment_1) { Fabricate(:comment) }
    let(:comment_2) { Fabricate(:comment) }

    describe "#initialize" do
      it 'take a problem like args' do
        expect(problem_destroy.problem).to eq problem
      end
    end

    describe "#execute" do
      it 'destroy the problem himself' do
        expect(problem).to receive(:delete).and_return(true)
        problem_destroy.execute
      end

      it 'delete all errs associate' do
        expect(Err).to receive(:delete_all).with(:id => [err_1.id, err_2.id])
        problem_destroy.execute
      end

      it 'delete all comments associate' do
        expect(Comment).to receive(:delete_all).with(:id => [comment_1.id, comment_2.id])
        problem_destroy.execute
      end

      it 'delete all notice of associate to this errs' do
        expect(Notice).to receive(:delete_all).with(:err_id => [err_1.id, err_2.id])
        problem_destroy.execute
      end
    end

  end

  context "in integration way" do
    let!(:problem) { Fabricate(:problem) }
    let!(:err_1) { Fabricate(:err, :problem => problem) }
    let!(:err_2) { Fabricate(:err, :problem => problem) }
    let!(:comment_1) { Fabricate(:comment, :err => err_1) }
    let!(:comment_2) { Fabricate(:comment, :err => err_2) }
    let!(:notice_1_1) { Fabricate(:notice, :err => err_1) }
    let!(:notice_1_2) { Fabricate(:notice, :err => err_1) }
    let!(:notice_2_1) { Fabricate(:notice, :err => err_2) }
    let!(:notice_2_2) { Fabricate(:notice, :err => err_2) }

    it 'should all destroy' do
      problem_destroy.execute
      expect(Problem.where(:id => problem.id).entries).to be_empty
      expect(Err.where(:id => err_1.id).entries).to be_empty
      expect(Err.where(:id => err_2.id).entries).to be_empty
      expect(Comment.where(:id => comment_1.id).entries).to be_empty
      expect(Comment.where(:id => comment_2.id).entries).to be_empty
      expect(Notice.where(:id => notice_1_1.id).entries).to be_empty
      expect(Notice.where(:id => notice_1_2.id).entries).to be_empty
      expect(Notice.where(:id => notice_2_1.id).entries).to be_empty
      expect(Notice.where(:id => notice_2_2.id).entries).to be_empty
    end
  end

end
