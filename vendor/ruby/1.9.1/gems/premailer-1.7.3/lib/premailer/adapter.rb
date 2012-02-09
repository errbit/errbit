# = HTTPI::Adapter
#
# Manages the adapter classes. Currently supports:
#
# * nokogiri
# * hpricot
class Premailer
  module Adapter

    autoload :Hpricot, 'premailer/adapter/hpricot'
    autoload :Nokogiri, 'premailer/adapter/nokogiri'

    REQUIREMENT_MAP = [
      ["hpricot",  :hpricot],
      ["nokogiri", :nokogiri],
    ]

    # Returns the adapter to use.
    def self.use
      return @use if @use
      self.use = self.default
      @use
    end

    # The default adapter based on what you currently have loaded and
    # installed. First checks to see if any adapters are already loaded,
    # then ckecks to see which are installed if none are loaded.
    def self.default
      return :hpricot  if defined?(::Hpricot)
      return :nokogiri if defined?(::Nokogiri)

      REQUIREMENT_MAP.each do |(library, adapter)|
        begin
          require library
          return adapter
        rescue LoadError
          next
        end
      end

      raise "No suitable adapter for Premailer was found, please install hpricot or nokogiri"
    end

    # Sets the +adapter+ to use. Raises an +ArgumentError+ unless the +adapter+ exists.
    def self.use=(new_adapter)
      @use = find(new_adapter)
    end

    # Returns an +adapter+. Raises an +ArgumentError+ unless the +adapter+ exists.
    def self.find(adapter)
      return adapter if adapter.is_a?(Module)

      Premailer::Adapter.const_get("#{adapter.to_s.split('_').map{|s| s.capitalize}.join('')}")
    rescue NameError
      raise ArgumentError, "Invalid adapter: #{adapter}"
    end

  end
end
