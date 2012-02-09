class AddDuplicateSurveySchema < Mongoid::Migration
  def self.up
    SurveySchema.create(:label => 'Duplicate Survey')
  end

  def self.down
    SurveySchema.where(:label => 'Duplicate Survey').first.destroy
  end
end