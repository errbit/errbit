require 'rubygems'
require 'mongo'
require "activerecord-import/base"

include Mongo
ActiveRecord::Import.require_adapter('postgresql')

module DataMigration
  def self.start(*args)
    worker = Worker.new(*args)
    worker.start
  end

  class DBPrepareMigration < ActiveRecord::Migration
    def self.up
      add_column :users, :remote_id, :string
      add_column :apps, :remote_id, :string
      add_column :backtraces, :remote_id, :string
      add_column :errs, :remote_id, :string
      add_column :problems, :remote_id, :string
      add_column :comments, :remote_id, :string
      add_column :notices, :remote_id, :string

      add_index :users, :remote_id
      add_index :apps, :remote_id
      add_index :backtraces, :remote_id
      add_index :errs, :remote_id
      add_index :problems, :remote_id
      add_index :comments, :remote_id
      add_index :notices, :remote_id
    end

  end

  class Worker
    # mapping should be a hash {:key_to => :key_from}
    # value of this hash can be an object and respond to :call, which returns value for new key
    USER_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :github_login => :github_login,
      :github_oauth_token => :github_oauth_token,
      :name => :name,
      :username => :username,
      :admin => :admin,
      :per_page => :per_page,
      :time_zone => :time_zone,
      :email => :email,
      :encrypted_password => :encrypted_password,
      :reset_password_token => :reset_password_token,
      :remember_token => :remember_token,
      :remember_created_at => :remember_created_at,
      :sign_in_count => :sign_in_count,
      :current_sign_in_at => :current_sign_in_at,
      :last_sign_in_at => :last_sign_in_at,
      :current_sign_in_ip => :current_sign_in_ip,
      :last_sign_in_ip => :last_sign_in_ip,
      :authentication_token => :authentication_token,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    APP_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :name => :name,
      :api_key => :api_key,
      :github_repo => :github_repo,
      :bitbucket_repo => :bitbucket_repo,
      :repository_branch => :repository_branch,
      :resolve_errs_on_deploy => :resolve_errs_on_deploy,
      :notify_all_users => :notify_all_users,
      :notify_on_errs => :notify_on_errs,
      :notify_on_deploys => :notify_on_deploys,
      :email_at_notices => :email_at_notices,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    DEPLOY_FIELDS_MAPPING = {
      :username => :username,
      :repository => :repository,
      :environment => :environment,
      :revision => :revision,
      :message => :message,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    WATCHER_FIELDS_MAPPING = {
      :email => :email,
      :user_id => lambda{|v| v["user_id"] ? User.where(:remote_id => v["user_id"].to_s).pluck(:id).first : nil  },
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    PROBLEM_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :app_id => lambda{|v| App.where(:remote_id => v["app_id"].to_s).pluck(:id).first},
      :last_notice_at => :last_notice_at,
      :first_notice_at => :first_notice_at,
      :last_deploy_at => :last_deploy_at,
      :resolved => :resolved,
      :resolved_at => :resolved_at,
      :issue_link => :issue_link,
      :issue_type => :issue_type,
      :app_name => :app_name,
      :notices_count => :notices_count,
      :comments_count => :comments_count,
      :message => :message,
      :environment => :environment,
      :error_class => :error_class,
      :where => :where,
      :user_agents => lambda{|v| normalize_hash(v["user_agents"])},
      :messages => lambda{|v| normalize_hash(v["messages"])},
      :hosts => lambda{|v| normalize_hash(v["hosts"])},
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    COMMENT_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :user_id => lambda{|v| User.where(:remote_id => v["user_id"].to_s).pluck(:id).first},
      :problem_id => lambda{|v| Problem.where(:remote_id => v["err_id"].to_s).pluck(:id).first},
      :body => :body,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    ERR_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :problem_id => lambda{|v| Problem.where(:remote_id => v["problem_id"].to_s).pluck(:id).first},
      :error_class => :error_class,
      :component => :component,
      :action => :action,
      :environment => :environment,
      :fingerprint => :fingerprint,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    BACKTRACE_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :fingerprint => :fingerprint,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    BACKTRACE_LINE_FIELDS_MAPPING = {
      :number => :number,
      :file => :file,
      :method => :method,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    NOTICE_FIELDS_MAPPING = {
      :remote_id => lambda{|v| v["_id"].to_s},
      :err_id => lambda{|v| Err.where(:remote_id => v["err_id"].to_s).pluck(:id).first},
      :backtrace_id => lambda{|v| Backtrace.where(:remote_id => v["backtrace_id"].to_s).pluck(:id).first},
      :server_environment => lambda{|v| normalize_hash(v["server_environment"])},
      :request => lambda{|v| normalize_hash(v["request"])},
      :notifier => lambda{|v| normalize_hash(v["notifier"])},
      :user_attributes => lambda{|v| normalize_hash(v["user_attributes"])},
      :current_user => lambda{|v| normalize_hash(v["current_user"])},
      :message => :message,
      :framework => :framework,
      :error_class => :error_class,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    ISSUE_TRACKER_FIELDS_MAPPING = {
      :project_id => :project_id,
      :alt_project_id => :alt_project_id,
      :api_token => :api_token,
      :account => :account,
      :username => :username,
      :password => :password,
      :ticket_properties => :ticket_properties,
      :subdomain => :subdomain,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    NOTIFICATION_SERVICE_FIELDS_MAPPING = {
      :room_id => :room_id,
      :user_id => :user_id,
      :service_url => :service_url,
      :service => :service,
      :api_token => :api_token,
      :subdomain => :subdomain,
      :sender_name => :sender_name,
      :created_at => :created_at,
      :updated_at => :updated_at
    }

    # get instance of Hash class from BSON::OrderedHash
    def self.normalize_hash(hash)
      ActiveSupport::JSON.decode(hash.to_json)
    end

    attr_reader :db, :mongo_client

    def initialize(config)
      config = config.with_indifferent_access
      config[:host] ||= 'localhost'
      config[:port] ||= 27017
      @mongo_client = MongoClient.new(config[:host], config[:port])
      @db = @mongo_client[config[:database].to_s]
      @import_options = {:timestamps => false}
    end

    def start
      db_prepare
      app_prepare

      copy_users
      copy_apps
      copy_problems
      copy_comments
      copy_errs
      copy_backtraces
      copy_notices

      update_states
    end

    def app_prepare
      Notice.observers.disable :all
      Deploy.observers.disable :all
    end

    def db_prepare
      return if Notice.column_names.include? "remote_id"
      DBPrepareMigration.migrate :up
    end

    def copy_users
      last_user = User.last
      options = {}

      if last_user
        remote_id = last_user.remote_id
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      find_each(db[:users], options) do |old_user|
        copy_user(old_user)
      end
    end

    def copy_apps
      last_app = App.last
      options = {}

      if last_app
        remote_id = last_app.remote_id
        options.deep_merge!({"_id" => {'$gt' => remote_id}})
      end

      find_each(db[:apps], options) do |old_app|
        app = copy_app(old_app)
        copy_deploys(old_app, app)
        copy_watchers(old_app, app)
      end
    end

    def copy_deploys(old_app, app)
      return unless old_app["deploys"]

      counter = 0
      total = old_app["deploys"].count
      log "  Start copy deploys, total: #{total}"

      old_app["deploys"].each do |deploy|
        log "    copying [deploy] ##{counter += 1} of #{total} with id '#{deploy['_id']}'"
        deploy = copy_deploy(app, deploy)
        deploy.save!
      end
    end

    def copy_watchers(old_app, app)
      return unless old_app["watchers"]
      counter = 0
      total = old_app["watchers"].count
      log "  Start copy watchers, total: #{total}"

      old_app["watchers"].each do |watcher|
        log "    copying [watcher] ##{counter += 1} of #{total} with id '#{watcher['_id']}'"

        copy_watcher(app, watcher)
      end
    end

    def copy_problems
      last_problem = Problem.last
      options = {}

      if last_problem
        remote_id = last_problem.remote_id
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      columns = PROBLEM_FIELDS_MAPPING.keys
      values = []
      find_each(db[:problems], options) do |old_problem|
        values << get_values(PROBLEM_FIELDS_MAPPING, old_problem)
        import_values_for(Problem, columns, values, @import_options.merge(:batch => 50, :validate => false))
      end
      import_values_for(Problem, columns, values, @import_options.merge(:validate => false))
    end

    def copy_comments
      last_comment = Comment.last
      options = {}

      if last_comment
        remote_id = last_comment.remote_id
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      columns = COMMENT_FIELDS_MAPPING.keys
      values = []
      find_each(db[:comments], options) do |old_comment|
        values << get_values(COMMENT_FIELDS_MAPPING, old_comment)
        import_values_for(Comment, columns, values, @import_options.merge(:batch => 50))
      end
      import_values_for(Comment, columns, values, @import_options)
    end

    def copy_errs
      last_err = Err.last
      options = {"problem_id" => {"$exists" => true}}

      if last_err
        remote_id = last_err.remote_id
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      columns = ERR_FIELDS_MAPPING.keys
      values = []
      find_each(db[:errs], options) do |old_err|
        values << get_values(ERR_FIELDS_MAPPING, old_err)
        import_values_for(Err, columns, values, @import_options.merge(:batch => 50, :validate => false))
      end
      import_values_for(Err, columns, values, @import_options.merge(:validate => false))
    end

    def copy_notices
      last_notice = Notice.last
      options = {}

      if last_notice
        remote_id = last_notice.remote_id
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      columns = NOTICE_FIELDS_MAPPING.keys
      values = []
      find_each(db[:notices], options) do |old_notice|
        values << get_values(NOTICE_FIELDS_MAPPING, old_notice)
        import_values_for(Notice, columns, values, @import_options.merge(:batch => 50, :validate => false))
      end
      import_values_for(Notice, columns, values, @import_options.merge(:validate => false))
    end

    def copy_backtraces
      last_backtrace = Backtrace.last
      options = {}

      if last_backtrace
        remote_id = last_backtrace.remote_id
        last_backtrace.lines.destroy_all
        options.deep_merge!({"_id" => {'$gt' => BSON::ObjectId(remote_id)}})
      end

      find_each(db[:backtraces], options) do |old_backtrace|
        copy_backtrace(old_backtrace)
      end
    end

    def update_states
      find_each(db[:problems], {}) do |old_problem|
        p = Problem.find_by_remote_id(old_problem["_id"].to_s)
        p.resolved = old_problem["resolved"]
        p.resolved_at = old_problem["resolved_at"]
        p.notices_count = old_problem["notices_count"]
        p.comments_count = old_problem["comments_count"]
        p.last_notice_at = old_problem["last_notice_at"]
        p.first_notice_at = old_problem["first_notice_at"]
        p.last_deploy_at = old_problem["last_deploy_at"]
        p.save
      end
    end

    private
      def copy_user(old_user)
        user = User.new
        copy_from_mapping(USER_FIELDS_MAPPING, old_user, user)

        # disable validation, cause devise require password. Try create "type" without password validation
        user.save(:validate => false)
        user
      end

      def copy_app(old_app)
        app = App.new
        copy_from_mapping(APP_FIELDS_MAPPING, old_app, app)
        app.save!

        copy_issue_tracker(app, old_app)
        copy_notification_service(app, old_app)

        app
      end

      def copy_issue_tracker(app, old_app)
        return unless old_app["issue_tracker"]
        issue_tracker = app.build_issue_tracker
        copy_from_mapping(ISSUE_TRACKER_FIELDS_MAPPING, old_app["issue_tracker"], issue_tracker)
        app.issue_tracker.type = normalize_issue_tracker_classname(old_app["issue_tracker"]["_type"])

        # disable validate because have problem with different schemas in db
        issue_tracker.save(:validate => false)
      end

      def copy_notification_service(app, old_app)
        return unless old_app["notification_service"]
        notification_service = app.build_notification_service
        copy_from_mapping(NOTIFICATION_SERVICE_FIELDS_MAPPING, old_app["notification_service"], notification_service)
        app.notification_service.type = normalize_notification_service_classname(old_app["notification_service"]["_type"])

        # disable validate because have problem with different schemas in db
        notification_service.save(:validate => false)
      end

      def normalize_issue_tracker_classname(name)
        return nil unless name[/IssueTrackers?::/]
        "IssueTrackers::#{name.demodulize}"
      end

      def normalize_notification_service_classname(name)
        return nil unless name[/NotificationServices?::/]
        "NotificationServices::#{name.demodulize}"
      end

      def copy_watcher(app, old_watcher)
        # not app.watchers.new, cause it's reason for memory leak (if you has many watchers)
        watcher = Watcher.new(:app_id => app.id)
        watcher.email = old_watcher["email"]
        if old_watcher["user_id"]
          watcher.user = User.find_by_remote_id(old_watcher["user_id"].to_s)
        end
        watcher.save!
        watcher
      end

      def copy_deploy(app, old_deploy)
        # not app.deploys.new, cause it's reason for memory leak (if you has many deploys)
        deploy = Deploy.new(:app_id => app.id)
        copy_from_mapping(DEPLOY_FIELDS_MAPPING, old_deploy, deploy)
        deploy
      end

      def copy_backtrace(old_backtrace)
        backtrace = Backtrace.new
        copy_from_mapping(BACKTRACE_FIELDS_MAPPING, old_backtrace, backtrace)
        copy_backtrace_lines(backtrace, old_backtrace)

        backtrace.save!
        backtrace
      end

      def copy_backtrace_lines(backtrace, old_backtrace)
        if old_backtrace["lines"]
          lines = []
          old_backtrace["lines"].each do |old_line|
            lines << copy_backtrace_line(backtrace, old_line)
          end
          BacktraceLine.import lines
        end
      end

      def copy_backtrace_line(backtrace, old_line)
        line = backtrace.lines.new
        copy_from_mapping(BACKTRACE_LINE_FIELDS_MAPPING, old_line, line)

        line
      end

      def find_each(collection, options = {})
        counter = 0
        total = collection.find(options).count
        log "Start copy #{collection.name}, total: #{total}"

        collection.find(options, :timeout => false, :sort => ["_id", "asc"]) do |cursor|
          counter = 0
          cursor.each do |item|
            log "  copying [#{collection.name}] ##{counter += 1} of #{total} with id '#{item["_id"]}'"
            yield item
          end
        end
      end

      def copy_from_mapping(map_hash, copy_from, copy_to)
        map_hash.each do |to_key, from_key|
          if from_key.respond_to? :call
            copy_to.send("#{to_key}=", from_key.call(copy_from))
          else
            from_key = from_key.to_s
            copy_to.send("#{to_key}=", copy_from[from_key]) if copy_from.has_key? from_key
          end
        end
      end

      def import_values_for(klass, columns, values, options = {})
        batch_size = options.delete(:batch)
        if !batch_size || (values.count >= batch_size)
          klass.import columns, values, options
          values.clear
        end
      end

      def get_values(map_hash, copy_from)
        copy_to = []
        map_hash.each do |to_key, from_key|
          copy_to << if from_key.respond_to? :call
            from_key.call(copy_from)
          else
            from_key = from_key.to_s
            copy_from[from_key] if copy_from.has_key? from_key
          end
        end
        copy_to
      end

      def log(message)
        puts "[#{Time.current.to_s(:db)}] #{message}"
      end
  end

end
