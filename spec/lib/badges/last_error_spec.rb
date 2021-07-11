RSpec.describe Badges::LastError do
  before(:each) do
    allow(Errbit::Config).to receive(:badge_last_error_steps).and_return([24, 48])
  end

  describe 'shows hours till last error' do
    let(:notice) { Fabricate(:notice) }
    let(:app) { notice.app }

    it 'red' do
      badge = Badges::LastError.new(notice.app)
      expect(badge.value_text).to eq "<1h"
      expect(badge.value_color).to eq Badges::Base::COLORS[:red]
    end

    it 'yellow' do
      notice.problem.update(last_notice_at: 26.hours.ago)

      badge = Badges::LastError.new(notice.app)
      expect(badge.value_text).to eq "1d"
      expect(badge.value_color).to eq Badges::Base::COLORS[:yellow]
    end

    it 'green' do
      notice.problem.update(last_notice_at: 50.hours.ago)

      badge = Badges::LastError.new(notice.app)
      expect(badge.value_text).to eq "2d"
      expect(badge.value_color).to eq Badges::Base::COLORS[:green]
    end
  end
end
