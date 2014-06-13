namespace :errbit do

  desc "Add a demo app & errors to your database (for testing)"
  task :demo => :environment do

    app = Fabricate(:app, :name => "Demo App #{Time.now.strftime("%N")}")

    # Report a number of errors for the application
    app.problems.delete_all

    errors = [{
      :error_class => "ArgumentError",
      :message => "wrong number of arguments (3 for 0)"
    }, {
      :error_class => "RuntimeError",
      :message => "Could not find Red October"
    }, {
      :error_class => "TypeError",
      :message => "can't convert Symbol into Integer"
    }, {
      :error_class => "ActiveRecord::RecordNotFound",
      :message => "could not find a record with the id 5"
    }, {
      :error_class => "NameError",
      :message => "uninitialized constant Tag"
    }, {
      :error_class => "SyntaxError",
      :message => "unexpected tSTRING_BEG, expecting keyword_do or '{' or '('"
    }]

    RANDOM_METHODS = ActiveSupport.methods.shuffle[1..8]

    def random_backtrace
      backtrace = []
      99.times {|t| backtrace << {
        'number'  => t.hash % 1000,
        'file'    => "/path/to/file.rb",
        'method'  => RANDOM_METHODS.shuffle.first.to_s
      }}
      backtrace
    end

    errors.each do |error_template|
      rand(34).times do
        ErrorReport.new(error_template.reverse_merge({
          :api_key => app.api_key,
          :error_class => "StandardError",
          :message => "Oops. Something went wrong!",
          :backtrace => random_backtrace,
          :request => {
            'component' => 'main',
            'action' => 'error',
            'url' => "http://example.com/post/#{[111, 222, 333].sample}",
          },
          :server_environment => {'environment-name' => Rails.env.to_s},
          :notifier => {:name => "seeds.rb"},
          :app_user => {
            :id => "1234",
            :username => "jsmith",
            :name => "John Smith",
            :url => "http://www.example.com/users/jsmith"
          }
        })).generate_notice!
      end
    end


    Fabricate(:notice, :err => Fabricate(:err, :problem => Fabricate(:problem, :app => app)))
    puts "=== Created demo app: '#{app.name}', with example errors."
  end

end
