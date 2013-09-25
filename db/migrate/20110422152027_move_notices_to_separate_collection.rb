class MoveNoticesToSeparateCollection < Mongoid::Migration
  def self.up
    errs_coll = connection["errs"]

    # copy embedded Notices into a separate collection
    errs = errs_coll.find.select(notices: 1)
    errs.each do |err|
      next unless err['notices']

      # This Err was created after the Problem->Err->Notice redesign
      next if err['app_id'].nil? or err['problem_id']

      e = Err.find(err['_id'])
      # disable email notifications
      old_notify = e.app.notify_on_errs?
      e.app.update_attribute(:notify_on_errs, false)
      puts "Copying notices for Err #{err['_id']}"
      err['notices'].each do |notice|
        e.notices.create!(notice)
      end
      e.app.update_attribute(:notify_on_errs, old_notify)
      errs_coll.find({ "_id" => err['_id']}).update({ "$unset" => { "notices" => 1}})
    end
    (
      Problem.where(:environment => '') |
      Problem.where(:environment => nil) |
      Problem.where(:environment => {})
    ).each {|pr|
      pr.update_attributes(:environment => 'old')
    }
    Rake::Task["errbit:db:update_notices_count"].invoke
    Rake::Task["errbit:db:update_problem_attrs"].invoke
  end

  def self.down
  end
end

