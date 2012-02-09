namespace :db do

  unless Rake::Task.task_defined?("db:drop")
    desc 'Drops all the collections for the database for the current Rails.env'
    task :drop => :environment do
      Mongoid.master.collections.select {|c| c.name !~ /system/ }.each { |c| c.drop }
    end
  end

  unless Rake::Task.task_defined?("db:seed")
    # if another ORM has defined db:seed, don't run it twice.
    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      seed_file = File.join(Rails.root, 'db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end
  end

  unless Rake::Task.task_defined?("db:setup")
    desc 'Create the database, and initialize with the seed data'
    task :setup => [ 'db:create', 'db:mongoid:create_indexes', 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:reseed")
    desc 'Delete data and seed'
    task :reseed => [ 'db:drop', 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:create")
    task :create => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:migrate")
    task :migrate => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:schema:load")
    namespace :schema do
      task :load do
        # noop
      end
    end
  end

  unless Rake::Task.task_defined?("db:test:prepare")
    namespace :test do
      task :prepare do
        # noop
      end
    end
  end

  unless Rake::Task.task_defined?("db:create_indexes")
    task :create_indexes => "mongoid:create_indexes"
  end

  namespace :mongoid do
    # gets a list of the mongoid models defined in the app/models directory
    def get_mongoid_models
      documents = []
      Dir.glob("app/models/**/*.rb").sort.each do |file|
        model_path = file[0..-4].split('/')[2..-1]
        begin
          klass = model_path.map { |path| path.camelize }.join('::').constantize
          if klass.ancestors.include?(Mongoid::Document) && !klass.embedded
            documents << klass
          end
        rescue => e
          # Just for non-mongoid objects that dont have the embedded
          # attribute at the class level.
        end
      end
      documents
    end

    desc 'Create the indexes defined on your mongoid models'
    task :create_indexes => :environment do
      ::Rails::Mongoid.create_indexes("app/models/**/*.rb")
    end

    def convert_ids(obj)
      if obj.is_a?(String) && obj =~ /^[a-f0-9]{24}$/
        BSON::ObjectId(obj)
      elsif obj.is_a?(Array)
        obj.map do |v|
          convert_ids(v)
        end
      elsif obj.is_a?(Hash)
        obj.each_pair do |k, v|
          obj[k] = convert_ids(v)
        end
      else
        obj
      end
    end

    def collection_names
      @collection_names ||= get_mongoid_models.map{ |d| d.collection.name }.uniq
    end

    desc "Convert string objectids in mongo database to ObjectID type"
    task :objectid_convert => :environment do
      collection_names.each do |collection_name|
        puts "Converting #{collection_name} to use ObjectIDs"

        # get old collection
        collection = Mongoid.master.collection(collection_name)

        # get new collection (a clean one)
        collection.db["#{collection_name}_new"].drop
        new_collection = collection.db["#{collection_name}_new"]

        # convert collection documents
        collection.find({}, :timeout => false, :sort => "_id") do |cursor|
           cursor.each do |doc|
            new_doc = convert_ids(doc)
            new_collection.insert(new_doc, :safe => true)
          end
        end

        puts "Done! Converted collection is in #{new_collection.name}\n\n"
      end

      # no errors. great! now rename _new to collection_name
      collection_names.each do |collection_name|
        collection = Mongoid.master.collection(collection_name)
        new_collection = collection.db["#{collection_name}_new"]

        # swap collection to _old
        puts "Moving #{collection.name} to #{collection_name}_old"
        collection.db["#{collection_name}_old"].drop

        begin
          collection.rename("#{collection_name}_old")
        rescue Exception => e
          puts "Unable to rename database #{collection_name} to #{collection_name}_old"
          puts "reason: #{e.message}\n\n"
        end

        # swap _new to collection
        puts "Moving #{new_collection.name} to #{collection_name}\n\n"

        begin
          new_collection.rename(collection_name)
        rescue Exception => e
          puts "Unable to rename database #{new_collection.name} to #{collection_name}"
          puts "reason: #{e.message}\n\n"
        end
      end

      puts "DONE! Run `rake db:mongoid:cleanup_old_collections` to remove old collections"
    end

    desc "Clean up old collections backed up by objectid_convert"
    task :cleanup_old_collections => :environment do
      collection_names.each do |collection_name|
        collection = Mongoid.master.collection(collection_name)
        collection.db["#{collection.name}_old"].drop
      end
    end

    ########
    # TODO: lots more useful db tasks can be added here. stuff like copyDatabase, etc
    ########
  end

end
