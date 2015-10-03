class CacheHostAndUserAgentOnNotice < ActiveRecord::Migration
  def up
    add_column :notices, :host, :string
    add_column :notices, :user_agent_string, :string

    require "progressbar"
    notices = Notice.all
    pbar = ProgressBar.new("notices", notices.count)
    notices.find_each do |notice|
      notice.send :set_host
      notice.send :set_user_agent_string
      Notice.where(id: notice.id).update_all(
        host: notice.host,
        user_agent_string: notice.user_agent_string)
      pbar.inc
    end
    pbar.finish
  end

  def down
    remove_column :notices, :host
    remove_column :notices, :user_agent_string
  end
end
