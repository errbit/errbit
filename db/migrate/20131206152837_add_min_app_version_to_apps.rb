class AddMinAppVersionToApps < Mongoid::Migration
  def change
    add_column :apps, :current_app_version, :string
  end
end