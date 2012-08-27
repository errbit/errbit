class ProblemPresenter
  
  def initialize(model_or_collection)
    @model_or_collection = model_or_collection
  end
  
  def to_xml(options={})
    as_json(options).to_xml(options)
  end
  
  def to_json(options={})
    Yajl.dump(as_json(options))
  end
  
  def as_json(options={})
    if collection?
      @model_or_collection.map { |model| model_as_json(model, options) }
    else
      model_as_json(@model_or_collection, options)
    end
  end
  
  def collection?
    @model_or_collection.respond_to?(:each)
  end
  
  def model_as_json(problem, options={})
    {
      app_id: problem.app_id,
      app_name: problem.app_name,
      environment: problem.environment,
      message: problem.message,
      where: problem.where,
      first_notice_at: problem.first_notice_at,
      last_notice_at: problem.last_notice_at,
      resolved: problem.resolved,
      resolved_at: problem.resolved_at,
      notices_count: problem.notices_count
    }
  end
  
end
