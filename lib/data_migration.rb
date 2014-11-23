require 'mongo'

include Mongo

class ActiveRecord::Base
  def self.without_callback(callback, &block)
    method = self.send(:instance_method, callback)
    begin
      self.send(:remove_method, callback)
      self.send(:define_method, callback) {true}
      yield
    ensure
      self.send(:remove_method, callback)
      self.send(:define_method, callback, method)
    end
  end
end

module DataMigration
  
  def self.start(configuration)
    worker = Worker.new(configuration)
    worker.start
  end

  class DBPrepareMigration < ActiveRecord::Migration
    self.verbose = false
    
    def change
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
    # mapping should be a hash {key_to: :key_from}
    # value of this hash can be an object and respond to :call, which returns value for new key
    USER_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      email: :email,
      github_login: :github_login,
      github_oauth_token: :github_oauth_token,
      name: :name,
      admin: :admin,
      per_page: :per_page,
      time_zone: :time_zone,
      
      encrypted_password: :encrypted_password,
      
      reset_password_token: :reset_password_token,
      reset_password_sent_at: :reset_password_sent_at,
      
      remember_created_at: :remember_created_at,
      
      sign_in_count: :sign_in_count,
      current_sign_in_at: :current_sign_in_at,
      last_sign_in_at: :last_sign_in_at,
      current_sign_in_ip: :current_sign_in_ip,
      last_sign_in_ip: :last_sign_in_ip,
      
      authentication_token: :authentication_token,
      
      created_at: :created_at,
      updated_at: :updated_at,
      
      username: :username
    }

    APP_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      name: :name,
      api_key: :api_key,
      github_repo: :github_repo,
      bitbucket_repo: :bitbucket_repo,
      asset_host: :asset_host,
      repository_branch: :repository_branch,
      resolve_errs_on_deploy: :resolve_errs_on_deploy,
      notify_all_users: :notify_all_users,
      notify_on_errs: :notify_on_errs,
      notify_on_deploys: :notify_on_deploys,
      email_at_notices: :email_at_notices,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    DEPLOY_FIELDS_MAPPING = {
      username: :username,
      repository: :repository,
      environment: :environment,
      revision: :revision,
      message: :message,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    WATCHER_FIELDS_MAPPING = {
      email: :email,
      user_id: lambda{|v| v["user_id"] ? User.where(remote_id: v["user_id"].to_s).pluck(:id).first : nil  },
      created_at: :created_at,
      updated_at: :updated_at
    }

    PROBLEM_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      app_id: lambda{|v| App.where(remote_id: v["app_id"].to_s).pluck(:id).first},
      
      last_notice_at: :last_notice_at,
      first_notice_at: :first_notice_at,
      last_deploy_at: :last_deploy_at,
      resolved: :resolved,
      resolved_at: :resolved_at,
      issue_link: :issue_link,
      issue_type: :issue_type,
      
      app_name: :app_name,
      notices_count: :notices_count,
      message: :message,
      environment: :environment,
      error_class: :error_class,
      where: :where,
      user_agents: lambda{|v| normalize_hash(v["user_agents"])},
      messages: lambda{|v| normalize_hash(v["messages"])},
      hosts: lambda{|v| normalize_hash(v["hosts"])},
      comments_count: :comments_count,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    COMMENT_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      user_id: lambda{|v| User.where(remote_id: v["user_id"].to_s).pluck(:id).first},
      problem_id: lambda{|v| Problem.where(remote_id: v["err_id"].to_s).pluck(:id).first},
      
      body: :body,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    ERR_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      problem_id: lambda{|v| Problem.where(remote_id: v["problem_id"].to_s).pluck(:id).first},
      
      fingerprint: :fingerprint,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    BACKTRACE_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      fingerprint: :fingerprint,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    BACKTRACE_LINE_FIELDS_MAPPING = {
      number: :number,
      column: :column,
      file: :file,
      method: :method,
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    NOTICE_FIELDS_MAPPING = {
      remote_id: lambda{|v| v["_id"].to_s},
      
      message: :message,
      server_environment: lambda{|v| normalize_hash(v["server_environment"])},
      request: lambda{|v| normalize_hash(v["request"])},
      notifier: lambda{|v| normalize_hash(v["notifier"])},
      user_attributes: lambda{|v| normalize_hash(v["user_attributes"])},
      framework: :framework,
      error_class: :error_class,
      
      err_id: lambda{|v| Err.where(remote_id: v["err_id"].to_s).pluck(:id).first},
      backtrace_id: lambda{|v| Backtrace.where(remote_id: v["backtrace_id"].to_s).pluck(:id).first},
      
      created_at: :created_at,
      updated_at: :updated_at
    }

    ISSUE_TRACKER_FIELDS_MAPPING = {
      project_id: :project_id,
      alt_project_id: :alt_project_id,
      api_token: :api_token,
      account: :account,
      username: :username,
      password: :password,
      ticket_properties: :ticket_properties,
      subdomain: :subdomain,
      created_at: :created_at,
      updated_at: :updated_at
    }

    NOTIFICATION_SERVICE_FIELDS_MAPPING = {
      room_id: :room_id,
      user_id: :user_id,
      service_url: :service_url,
      service: :service,
      api_token: :api_token,
      subdomain: :subdomain,
      sender_name: :sender_name,
      created_at: :created_at,
      updated_at: :updated_at
    }

    # The collections to be copied in the order in which they should copied
    COLLECTIONS = [:users, :apps, :problems, :comments, :errs, :backtraces, :notices].freeze

    # get instance of Hash class from BSON::OrderedHash
    def self.normalize_hash(hash)
      ActiveSupport::JSON.decode(hash.to_json)
    end

    attr_reader :db, :mongo_client

    def initialize(configuration)
      session = configuration.with_indifferent_access[:sessions][:default]
      
      database = session[:database].to_s
      host = session.fetch(:hosts, []).first
      host, port = host.split(":") if host
      @mongo_client = MongoClient.new(host, port)
      
      username = session[:username]
      password = session[:password]
      mongo_client.add_auth(database, username, password, nil) if username && password
      
      @db = mongo_client[database]
    end

    def start
      prepare
      copy_all!
    ensure
      teardown
    end

    def prepare
      db_prepare
      app_prepare
    end
    
    def teardown
      db_teardown
      app_teardown
    end

    def app_prepare
      Notice.observers.disable :all
      Deploy.observers.disable :all
    end

    def db_prepare
      return if Notice.column_names.include? "remote_id"
      DBPrepareMigration.migrate :up
      [User, App, Deploy, Comment, Problem, Err, Notice, Backtrace].each(&:reset_column_information)
    end

    def db_teardown
      DBPrepareMigration.migrate :down
      [User, App, Deploy, Comment, Problem, Err, Notice, Backtrace].each(&:reset_column_information)
    end
    
    def app_teardown
      Notice.observers.enable :all
      Deploy.observers.enable :all
    end
    
    def copy_all!
      ActiveRecord::Base.transaction do
        COLLECTIONS.each(&method(:copy!))
      end
    end

    def copy!(collection)
      singular = collection.to_s.singularize
      mapping = self.class.const_get "#{singular.upcase}_FIELDS_MAPPING"
      save_method = method :"save_#{singular}!"
      
      without_callbacks do
        find_each(db[collection]) do |old_record|
          new_record = build_record_for_collection(collection)
          copy_attributes_with_mapping(mapping, old_record, new_record)
          save_method.call(new_record, old_record)
        end
      end
    end
    
    def without_callbacks(&block)
      callbacks = %w{
        Comment#deliver_email
        Comment#increase_counter_cache
        Deploy#resolve_app_errs
        Deploy#store_cached_attributes_on_problems
        Deploy#deliver_email
        Notice#cache_attributes_on_problem
        Notice#unresolve_problem
        Notice#email_notification
        Notice#services_notification
      }
      without_callbacks_recursive(callbacks, &block)
    end
    
    def without_callbacks_recursive(callbacks, &block)
      callback = callbacks.shift
      return yield unless callback
      
      model, method = callback.split("#")
      model.constantize.without_callback(method.to_sym) do
        without_callbacks_recursive(callbacks, &block)
      end
    end
    
    def build_record_for_collection(collection)
      model = collection.to_s.classify.constantize
      model.new
    end
    
    
    
    def save_user!(user, _)
      # so that Devise doesn't fail validation due to missing password
      def user.password_required?; false; end
      user.save!
    end
    
    def save_app!(app, old_app)
      app.save!
      copy_issue_tracker(app, old_app)
      copy_notification_service(app, old_app)
      copy_deploys(old_app, app)
      copy_watchers(old_app, app)
    end
    
    def save_problem!(problem, _)
      problem.save!
    end
    
    def save_comment!(comment, _)
      comment.save!
    end
    
    def save_err!(err, _)
      err.save!
    end
    
    def save_backtrace!(backtrace, old_backtrace)
      copy_backtrace_lines(backtrace, old_backtrace)
      backtrace.save!
    end
    
    def save_notice!(notice, _)
      notice.save!
    end
    
    
    
    
    def copy_deploys(old_app, app)
      return unless old_app["deploys"]
      
      old_app["deploys"].each do |deploy|
        deploy = copy_deploy(app, deploy)
        deploy.save!
      end
    end

    def copy_watchers(old_app, app)
      return unless old_app["watchers"]
      
      old_app["watchers"].each do |watcher|
        copy_watcher(app, watcher)
      end
    end

    private

      def copy_issue_tracker(app, old_app)
        return unless old_app["issue_tracker"]
        issue_tracker = app.build_issue_tracker
        copy_attributes_with_mapping(ISSUE_TRACKER_FIELDS_MAPPING, old_app["issue_tracker"], issue_tracker)
        app.issue_tracker.type = normalize_issue_tracker_classname(old_app["issue_tracker"]["_type"])

        # disable validate because have problem with different schemas in db
        issue_tracker.save(validate: false)
      end

      def copy_notification_service(app, old_app)
        return unless old_app["notification_service"]
        notification_service = app.build_notification_service
        copy_attributes_with_mapping(NOTIFICATION_SERVICE_FIELDS_MAPPING, old_app["notification_service"], notification_service)
        app.notification_service.type = normalize_notification_service_classname(old_app["notification_service"]["_type"])

        # disable validate because have problem with different schemas in db
        notification_service.save(validate: false)
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
        watcher = Watcher.new(app_id: app.id)
        watcher.email = old_watcher["email"]
        if old_watcher["user_id"]
          watcher.user = User.find_by_remote_id(old_watcher["user_id"].to_s)
        end
        watcher.save!
        watcher
      end

      def copy_deploy(app, old_deploy)
        # not app.deploys.new, cause it's reason for memory leak (if you has many deploys)
        deploy = Deploy.new(app_id: app.id)
        copy_attributes_with_mapping(DEPLOY_FIELDS_MAPPING, old_deploy, deploy)
        deploy
      end

      def copy_backtrace_lines(backtrace, old_backtrace)
        if old_backtrace["lines"]
          old_backtrace["lines"].each do |old_line|
            line = backtrace.lines.build
            copy_attributes_with_mapping(BACKTRACE_LINE_FIELDS_MAPPING, old_line, line)
          end
        end
      end

      def find_each(collection, options = {})
        total = collection.find(options).count
        log "Start copy #{collection.name}, total: #{total}"

        collection.find(options, timeout: false, sort: ["_id", "asc"]) do |cursor|
          counter = 0
          cursor.each do |item|
            log "  copying [#{collection.name}] ##{counter += 1} of #{total} with id '#{item["_id"]}'"
            yield item
          end
        end
      end

      def copy_attributes_with_mapping(map_hash, copy_from, copy_to)
        map_hash.each do |to_key, from_key|
          if from_key.respond_to? :call
            copy_to.send("#{to_key}=", from_key.call(copy_from))
          else
            from_key = from_key.to_s
            copy_to.send("#{to_key}=", copy_from[from_key]) if copy_from.has_key? from_key
          end
        end
      end

      def log(message)
        puts "[#{Time.current.to_s(:db)}] #{message}" unless Rails.env.test?
      end

  end

end
