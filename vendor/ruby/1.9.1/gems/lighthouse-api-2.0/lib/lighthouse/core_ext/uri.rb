begin
  require 'uri'
  require 'addressable/uri'

  module URI
    def decode(*args)
      Addressable::URI.decode(*args)
    end

    def escape(*args)
      Addressable::URI.escape(*args)
    end

    def parse(*args)
      Addressable::URI.parse(*args)
    end
  end
rescue LoadError => e
  puts "Install the Addressable gem (with dependencies) to support accounts with subdomains."
  puts "# sudo gem install addressable --development"
  puts e.message
end