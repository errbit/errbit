module PivotalTracker
  class Task
    include HappyMapper

    class << self
      def all(story, options={})
        tasks = parse(Client.connection["/projects/#{story.project_id}/stories/#{story.id}/tasks"].get)
        tasks.each { |t| t.project_id, t.story_id = story.project_id, story.id }
        return tasks
      end
    end

    attr_accessor :project_id, :story_id

    element :id, Integer
    element :description, String
    element :position, Integer
    element :complete, Boolean
    element :created_at, DateTime

    def create
      response = Client.connection["/projects/#{project_id}/stories/#{story_id}/tasks"].post(self.to_xml, :content_type => 'application/xml')
      return Task.parse(response)
    end

    def update
      response = Client.connection["/projects/#{project_id}/stories/#{story_id}/tasks/#{id}"].put(self.to_xml, :content_type => 'application/xml')
      return Task.parse(response)
    end

    def delete
      Client.connection["/projects/#{project_id}/stories/#{story_id}/tasks/#{id}"].delete
    end

    protected

      def to_xml
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.task {
            xml.description "#{description}"
            # xml.position "#{position}"
            xml.complete "#{complete}"
          }
        end
        return builder.to_xml
      end

  end

  class Task
    include Validation
  end
end
