require 'cgi'
require 'rest_client'
require 'happymapper'
require 'nokogiri'


require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'validation')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'extensions')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'proxy')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'client')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'project')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'attachment')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'story')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'task')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'membership')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'activity')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'iteration')
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'note')

module PivotalTracker

  # define error types
  class ProjectNotSpecified < StandardError; end

  def self.encode_options(options)
    options_strings = options.inject({}) do |m, (k,v)|
      if [:limit, :offset].include?(k.to_sym)
        m.update k => v
      elsif k.to_sym == :search
        m.update :filter => v
      else
        filter_query = %{#{k}:#{[v].flatten.join(",")}}
        m.update :filter => (m[:filter] ? "#{m[:filter]} #{filter_query}" : filter_query)
      end
    end.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}"}

    %{?#{options_strings.join("&")}} unless options_strings.empty?
  end

end
