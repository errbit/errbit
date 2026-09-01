# frozen_string_literal: true

namespace :errbit do
  desc "Add a demo app & errors to your database (for testing)"
  task demo: :environment do
    require "factory_bot_rails"

    app = FactoryBot.create(:app, name: "Demo App #{Time.zone.now.strftime("%N")}")

    # Report a number of errors for the application
    app.problems.delete_all

    errors = [{
      error_class: "ArgumentError",
      message: "wrong number of arguments (3 for 0)"
    }, {
      error_class: "RuntimeError",
      message: "Could not find Red October"
    }, {
      error_class: "TypeError",
      message: "can't convert Symbol into Integer"
    }, {
      error_class: "ActiveRecord::RecordNotFound",
      message: "could not find a record with the id 5"
    }, {
      error_class: "NameError",
      message: "uninitialized constant Tag"
    }, {
      error_class: "SyntaxError",
      message: "unexpected tSTRING_BEG, expecting keyword_do or '{' or '('"
    }]

    random_methods = ActiveSupport.methods.shuffle[1..8]
    demo_post_id = [111, 222, 333].sample

    def random_backtrace(random_methods)
      backtrace = []
      99.times do |t|
        backtrace << {
          "number" => t.hash % 1000,
          "file" => "/path/to/file.rb",
          "method" => random_methods.sample.to_s
        }
      end
      backtrace
    end

    demo_request = {
      "component" => "main",
      "action" => "error",
      "url" => "https://demo-user:demo-password@example.com/post/#{demo_post_id}?user_id=123&password=demo-password&api_key=demo-api-key#demo-fragment",
      "params" => {
        "user_id" => 123,
        "password" => "demo-password",
        "nested" => {"api_key" => "demo-api-key", "safe" => "visible"}
      },
      "session" => {
        "locale" => "en",
        "csrf_token" => "demo-csrf-token"
      },
      "cgi-data" => {
        "REQUEST_METHOD" => "GET",
        "QUERY_STRING" => "user_id=123&password=demo-password&api_key=demo-api-key",
        "REQUEST_URI" => "/post/#{demo_post_id}?user_id=123&password=demo-password&api_key=demo-api-key",
        "HTTP_COOKIE" => "session=demo-session",
        "HTTP_AUTHORIZATION" => "Bearer demo-token",
        "action_dispatch_secret_key_base" => "demo-secret",
        "rack.input" => "demo-internal-value"
      }
    }
    demo_server_environment = {
      "environment-name" => Rails.env.to_s,
      "secret_key_base" => "demo-secret",
      "safe_setting" => "visible"
    }
    demo_notifier = {
      "name" => "seeds.rb",
      "authorization" => "Bearer demo-token"
    }
    demo_user_attributes = {
      "id" => "1234",
      "username" => "jsmith",
      "name" => "John Smith",
      "api_token" => "demo-api-token"
    }

    errors.each do |error_template|
      rand(34).times do
        ErrorReport.new(
          error_template.reverse_merge(
            api_key: app.api_key,
            error_class: "StandardError",
            message: "Oops. Something went wrong!",
            backtrace: random_backtrace(random_methods),
            request: demo_request,
            server_environment: demo_server_environment,
            notifier: demo_notifier,
            app_user: demo_user_attributes
          )
        ).generate_notice!
      end
    end

    problem = FactoryBot.create(:problem, app: app)
    err = FactoryBot.create(:err, problem: problem)
    FactoryBot.create(:notice,
      app: app,
      err: err,
      request: demo_request,
      server_environment: demo_server_environment,
      notifier: demo_notifier,
      user_attributes: demo_user_attributes)

    puts "=== Created demo app: '#{app.name}', with example errors."
    puts "=== Privacy canary: inspect the latest notice for [FILTERED] values."
    puts "=== Disable ERRBIT_SANITIZE_NOTICE_DATA only if you intentionally want the fake secrets visible."
  end
end
