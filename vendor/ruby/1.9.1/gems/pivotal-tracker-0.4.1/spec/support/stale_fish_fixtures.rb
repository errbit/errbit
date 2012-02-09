module StaleFishFixtures
  class << self

    def update_projects_fixture
      connection["/projects"].get
    end

    def update_project_fixture
      connection["/projects/102622"].get
    end

    def update_stories_fixture
      connection["/projects/102622/stories?limit=20"].get
    end

    def update_memberships_fixture
      connection["/projects/102622/memberships"].get
    end

    def update_tasks_fixture
      connection["/projects/102622/stories/4459994/tasks"].get
    end

    def update_activity_fixture
      connection["/activities"].get
    end

    def update_project_activity_fixture
      connection["/projects/102622/activities"].get
    end

    def update_iterations_all_fixture
      connection["/projects/102622/iterations"].get
    end

    def update_iterations_current_fixture
      connection["/projects/102622/iterations/current"].get
    end

    def update_iterations_backlog_fixture
      connection["/projects/102622/iterations/backlog"].get
    end

    def update_iterations_done_fixture
      connection["/projects/102622/iterations/done"].get
    end

    def create_new_story
      connection["/projects/102622/stories"].post("<story><name>Create stuff</name></story>", :content_type => 'application/xml')
    end

    def update_notes_fixture
      connection["/projects/102622/stories/4460038/notes"].get
    end

#    def upload_attachment_fixture
#      connection["/projects/102622/stories/4473735/attachments"].post(:Filedata => File.new(File.dirname(__FILE__) + '/../../LICENSE'))
#    end

    protected

      def connection
        @connection ||= RestClient::Resource.new('http://www.pivotaltracker.com/services/v3', :headers => {'X-TrackerToken' => TOKEN, 'Content-Type' => 'application/xml'})
      end

  end
end
