class SurveySchema
  include Mongoid::Document
	include Mongoid::Timestamps
	
	field :label
end