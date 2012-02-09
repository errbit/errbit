module Lighthouse
  # Find tickets
  #
  #  Lighthouse::Ticket.find(:all, :params => { :project_id => 44 })
  #  Lighthouse::Ticket.find(:all, :params => { :project_id => 44, :q => "state:closed tagged:committed" })
  #
  #  project = Lighthouse::Project.find(44)
  #  project.tickets
  #  project.tickets(:q => "state:closed tagged:committed")
  #
  # Creating a Ticket
  #
  #  ticket = Lighthouse::Ticket.new(:project_id => 44)
  #  ticket.title = 'asdf'
  #  ...
  #  ticket.tags << 'ruby' << 'rails' << '@high'
  #  ticket.save
  #
  # Updating a Ticket
  #
  #  ticket = Lighthouse::Ticket.find(20, :params => { :project_id => 44 })
  #  ticket.state = 'resolved'
  #  ticket.tags.delete '@high'
  #  ticket.save
  #
  class Ticket < Base
    
    attr_writer :tags
    site_format << '/projects/:project_id'

    def id
      attributes['number'] ||= nil
      number
    end

    def tags
      attributes['tag'] ||= nil
      @tags ||= tag.blank? ? [] : parse_with_spaces(tag)
    end

    def body
      attributes['body'] ||= ''
    end

    def body=(value)
      attributes['body'] = value
    end

    def body_html
      attributes['body_html'] ||= ''
    end

    def body_html=(value)
      attributes['body_html'] = value
    end

    def save_with_tags
      self.tag = self.tags.collect do |tag|
        tag.include?(' ') ? tag.inspect : tag
      end.join(" ") if self.tags.is_a?(Array)
      
      self.tags = nil
      
      save_without_tags
    end
    
    alias_method_chain :save, :tags

    private
      # taken from Lighthouse Tag code
      def parse_with_spaces(list)
        tags = []

        # first, pull out the quoted tags
        list.gsub!(/\"(.*?)\"\s*/ ) { tags << $1; "" }
        
        # then, get whatever's left
        tags.concat list.split(/\s/)

        cleanup_tags(tags)
      end
    
      def cleanup_tags(tags)
        returning tags do |tag|
          tag.collect! do |t|
            unless tag.blank?
              t = Tag.new(t,prefix_options[:project_id])
              t.downcase!
              t.gsub! /(^')|('$)/, ''
              t.gsub! /[^a-z0-9 \-_@\!']/, ''
              t.strip!
              t.prefix_options = prefix_options
              t
            end
          end
          tag.compact!
          tag.uniq!
        end
      end
  end
end
