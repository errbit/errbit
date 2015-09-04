class MigrateEmbedsManyToHasMany < Mongoid::Migration
  def self.up
    collection = Mongoid.default_session[:deploys]

    App.each do |app|
      if app.attributes['deploys'].present?
        app.attributes['deploys'].each do |deploy|
          deploy.attributes['app_id'] = app.id
          collection.insert(deploy.attributes)
        end

        app.deploys = nil
        app.unset(:deploys)
        app.save
      end
    end
  end

  def self.down
  end
end
