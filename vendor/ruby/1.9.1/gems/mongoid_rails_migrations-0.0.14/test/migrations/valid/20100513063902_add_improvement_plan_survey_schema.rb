class AddImprovementPlanSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:label => 'Improvement Plan Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Improvement Plan Survey').first.destroy
  end
end