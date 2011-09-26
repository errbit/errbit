namespace :errbit do
  
  desc "Add a demo app & errors to your database (for testing)"
  task :demo => :environment do
    require 'factory_girl_rails'
    
    Dir.glob(File.join(Rails.root,  'spec/factories/*.rb')).each {|f| require f }
    app = Factory(:app, :name => "Demo App #{Time.now.strftime("%N")}")
    
    # Report a number of errors for the application
    app.problems.delete_all
    
    errors = [{
      :klass => "ArgumentError",
      :message => "wrong number of arguments (3 for 0)"
    }, {
      :klass => "RuntimeError",
      :message => "Could not find Red October"
    }, {
      :klass => "TypeError",
      :message => "can't convert Symbol into Integer"
    }, {
      :klass => "ActiveRecord::RecordNotFound",
      :message => "could not find a record with the id 5"
    }, {
      :klass => "NameError",
      :message => "uninitialized constant Tag"
    }, {
      :klass => "SyntaxError",
      :message => "unexpected tSTRING_BEG, expecting keyword_do or '{' or '('"
    }]
    
    RANDOM_METHODS = ActiveSupport.methods.shuffle[1..8]
    
    def random_backtrace
      backtrace = []
      99.times {|t| backtrace << {
        'number'  => t.hash % 1000,
        'file'    => "/path/to/file.rb",
        'method'  => RANDOM_METHODS.shuffle.first
      }}
      backtrace
    end
    
    errors.each do |error_template|
      rand(34).times do
        
        error_report = error_template.reverse_merge({
          :klass => "StandardError",
          :message => "Oops. Something went wrong!",
          :backtrace => random_backtrace,
          :request => {
                        'component' => 'main',
                        'action' => 'error'
                      },
          :server_environment => {'environment-name' => Rails.env.to_s},
          :notifier => {:name => "seeds.rb"}
        })
        
        app.report_error!(error_report)
      end
    end
    
    
    Factory(:notice, :err => Factory(:err, :problem => Factory(:problem, :app => app)))
    puts "=== Created demo app: '#{app.name}', with example errors."
  end
  
end
