module PivotalTracker
  class Note
    include HappyMapper

    class << self
      def all(story, options={})
        notes = parse(Client.connection["/projects/#{story.project_id}/stories/#{story.id}/notes"].get)
        notes.each { |n| n.project_id, n.story_id = story.project_id, story.id }
        return notes
      end
    end

    attr_accessor :project_id, :story_id

    element :id, Integer
    element :text, String
    element :author, String
    element :noted_at, DateTime
    has_one :story, Story

    def initialize(attributes={})
      if attributes[:owner]
        self.story = attributes.delete(:owner) 
        self.project_id = self.story.project_id
        self.story_id = self.story.id
      end

      update_attributes(attributes)
    end
    
    def create
      response = Client.connection["/projects/#{project_id}/stories/#{story_id}/notes"].post(self.to_xml, :content_type => 'application/xml')
      return Note.parse(response)
    end

    # Pivotal Tracker API doesn't seem to support updating or deleting notes at this time.

    protected

      def to_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.note {
            #xml.author "#{author}"
            xml.text_ "#{text}"
            xml.noted_at "#{noted_at}"
          }
        end
        return builder.to_xml
      end

      def update_attributes(attrs)
        attrs.each do |key, value|
          self.send("#{key}=", value.is_a?(Array) ? value.join(',') : value )
        end
      end
      
  end
end
