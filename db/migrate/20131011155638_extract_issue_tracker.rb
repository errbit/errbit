class ExtractIssueTracker < Mongoid::Migration

  def self.up
    App.collection.find.each do |app|
      if app['issue_tracker'] && !app['issue_tracker'].empty?
        it = app['issue_tracker']
        it['type_tracker'] = 'IssueTrackers::BitbucketIssuesTracker'
        it['options'] = app['issue_tracker'].dup
        it.delete('_type')
        App.collection.find(
          :_id => app['_id']
        ).update(app)
      end
    end
  end

  def self.down
  end
end
