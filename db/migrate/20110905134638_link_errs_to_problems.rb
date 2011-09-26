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
      if err['app_id'] && app = App.where(:_id => err['app_id']).first
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

