module Heroku
  module Updater
    def self.home_directory
      ENV['HOME'] || ENV['USERPROFILE']
    end

    def self.running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def self.updated_client_path
      File.join(home_directory, ".heroku", "client")
    end

    def self.disable(message=nil)
      @disable = message if message
      @disable
    end

    def self.update(beta=false)
      require "fileutils"
      require "tmpdir"
      require "zip/zip"

      FileUtils.mkdir_p updated_client_path

      client_path = nil

      zip_url = beta ?
        "http://assets.heroku.com/heroku-client/heroku-client-beta.zip" :
        "http://assets.heroku.com/heroku-client/heroku-client.zip"

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          File.open("heroku.zip", "wb") do |file|
            file.print RestClient.get zip_url
          end

          Zip::ZipFile.open("heroku.zip") do |zip|
            zip.each do |entry|
              target = File.join(updated_client_path, entry.to_s)
              FileUtils.mkdir_p File.dirname(target)
              zip.extract(entry, target) { true }
            end
          end
        end
      end
    end

    def self.inject_libpath
      $:.unshift File.join(updated_client_path, "lib")
      vendored_gems = Dir[File.join(updated_client_path, "vendor", "gems", "*")]
      vendored_gems.each do |vendored_gem|
        $:.unshift File.join(vendored_gem, "lib")
      end
    end
  end
end
