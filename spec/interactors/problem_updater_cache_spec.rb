require 'spec_helper'

describe ProblemUpdaterCache do
  let(:problem) { Fabricate(:problem_with_errs) }
  let(:first_errs) { problem.errs }
  let!(:notice) { Fabricate(:notice, :err => first_errs.first) }

  describe "#update" do
    context "without notice pass args" do
      before do
        problem.update_attribute(:notices_count, 0)
      end

      it 'update the notice_count' do
        expect {
          ProblemUpdaterCache.new(problem).update
        }.to change{
          problem.notices_count
        }.from(0).to(1)
      end

      context "with only one notice" do
        before do
          problem.update_attributes!(:messages => {})
          ProblemUpdaterCache.new(problem).update
        end

        it 'update information about this notice' do
          expect(problem.message).to eq notice.message
          expect(problem.where).to eq notice.where
        end

        it 'update first_notice_at' do
          expect(problem.first_notice_at).to eq notice.created_at
        end

        it 'update last_notice_at' do
          expect(problem.last_notice_at).to eq notice.created_at
        end

        it 'update stats messages' do
          expect(problem.messages).to eq({
            Digest::MD5.hexdigest(notice.message) => {'value' => notice.message, 'count' => 1}
          })
        end

        it 'update stats hosts' do
          expect(problem.hosts).to eq({
            Digest::MD5.hexdigest(notice.host) => {'value' => notice.host, 'count' => 1}
          })
        end

        it 'update stats user_agents' do
          expect(problem.user_agents).to eq({
            Digest::MD5.hexdigest(notice.user_agent_string) => {'value' => notice.user_agent_string, 'count' => 1}
          })
        end
      end

      context "with several notices" do
        let!(:notice_2) { Fabricate(:notice, :err => first_errs.first) }
        let!(:notice_3) { Fabricate(:notice, :err => first_errs.first) }
        before do
          problem.update_attributes!(:messages => {})
          ProblemUpdaterCache.new(problem).update
        end
        it 'update information about this notice' do
          expect(problem.message).to eq notice.message
          expect(problem.where).to eq notice.where
        end

        it 'update first_notice_at' do
          expect(problem.first_notice_at.to_i).to be_within(1).of(notice.created_at.to_i)
        end

        it 'update last_notice_at' do
          expect(problem.last_notice_at.to_i).to be_within(1).of(notice.created_at.to_i)
        end

        it 'update stats messages' do
          expect(problem.messages).to eq({
            Digest::MD5.hexdigest(notice.message) => {'value' => notice.message, 'count' => 3}
          })
        end

        it 'update stats hosts' do
          expect(problem.hosts).to eq({
            Digest::MD5.hexdigest(notice.host) => {'value' => notice.host, 'count' => 3}
          })
        end

        it 'update stats user_agents' do
          expect(problem.user_agents).to eq({
            Digest::MD5.hexdigest(notice.user_agent_string) => {'value' => notice.user_agent_string, 'count' => 3}
          })
        end

      end
    end

    context "with notice pass in args" do

      before do
        ProblemUpdaterCache.new(problem, notice).update
      end

      it 'increase notices_count by 1' do
        expect {
          ProblemUpdaterCache.new(problem, notice).update
        }.to change{
          problem.notices_count
        }.by(1)
      end

      it 'update information about this notice' do
        expect(problem.message).to eq notice.message
        expect(problem.where).to eq notice.where
      end

      it 'update first_notice_at' do
        expect(problem.first_notice_at).to eq notice.created_at
      end

      it 'update last_notice_at' do
        expect(problem.last_notice_at).to eq notice.created_at
      end

      it 'inc stats messages' do
        expect(problem.messages).to eq({
          Digest::MD5.hexdigest(notice.message) => {'value' => notice.message, 'count' => 2}
        })
      end

      it 'inc stats hosts' do
        expect(problem.hosts).to eq({
          Digest::MD5.hexdigest(notice.host) => {'value' => notice.host, 'count' => 2}
        })
      end

      it 'inc stats user_agents' do
        expect(problem.user_agents).to eq({
          Digest::MD5.hexdigest(notice.user_agent_string) => {'value' => notice.user_agent_string, 'count' => 2}
        })
      end
    end
  end
end
