module Heroku
  module Distribution
    def self.files
      Dir[File.expand_path("../../../{bin,data,lib}/**/*", __FILE__)].select do |file|
        File.file?(file)
      end
    end
  end
end
