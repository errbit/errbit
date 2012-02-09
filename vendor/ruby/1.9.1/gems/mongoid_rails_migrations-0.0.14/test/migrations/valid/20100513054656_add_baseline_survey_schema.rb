class AddBaselineSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:id => '4c47bf87f3395c339c000001',
                        :label => 'Baseline Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Baseline Survey').first.destroy
  end
end