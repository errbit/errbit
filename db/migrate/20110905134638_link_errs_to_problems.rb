class LinkErrsToProblems < Mongoid::Migration
  def self.up
    
    # Copy err.klass to notice.klass
    Notice.all.each do |notice|
      if notice.err && (klass = notice.err['klass'])
        notice.update_attribute(:klass, klass)
      end
    end
    
    # Create a Problem for each Err
    Err.all.each do |err|
      app_id = err['app_id']
      app = app_id && App.where(:_id => app_id).first
      if app
        err.problem = app.problems.create
        err.save
      end
    end
    
    Rake::Task["errbit:db:update_notices_count"].invoke
    Rake::Task["errbit:db:update_problem_attrs"].invoke
  end
  
  def self.down
  end
end