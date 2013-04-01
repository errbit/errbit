class IssueTrackers::JiraTracker < IssueTracker
  Label = "jira"
  Fields = [

            [:account, {
               :label => "Domain",
               :placeholder => "Your domain, recommended SSL (e.g. https://issues.apache.org/jira)"
             }],


            [:username, {
               :placeholder => "Your username for basic authentication"
             }],

            [:password, {
               :placeholder => "Your password for basic authentication"
             }],

            [:project_id, {
               :label       => "Project key",
               :placeholder => "It prefixes each issue in Jira (e.g. KAM)"
             }]
           ]
  
  class Data
    ISSUE_TYPE = "Bug"
    attr_accessor :project_key
    attr_accessor :summary, :description
    attr_accessor :user
    def initialize(project_key, user = nil)
      self.project_key = project_key
      self.user = user
    end
    
    def to_json
      fields.to_json
    end
    
    def fields
      add_basic_fields
      add_reporter if user.present?
      { "fields" => hash }
    end
    
    private
    def hash
      @hash ||= {}
    end
    
    def username
      UserNameFromEmailExtractor.new(user.email).extract
    end
    
    def add_basic_fields
      hash.merge!(
        "summary" => summary,
        "description" => description,
        "project" => {  "key" => project_key },
        "issuetype" => { "name" => ISSUE_TYPE }
        )
    end
    def add_reporter
      hash.merge!(
        "reporter" => { "name" => username }
        )
    end
  end
  
  class JiraLinkGenerator
    POST_ISSUE = "/rest/api/2/issue"
    def initialize(url)
      @url = url
    end
    
    def api_post_issue
      "#{url}#{POST_ISSUE}"
    end
    
    def project_page(key)
      "#{url}/browse/#{key}"
    end
    
    def issue_page(key)
      project_page(key)
    end
    
    private
    def url
      remove_trailing_slash(@url)
    end   
    
    def remove_trailing_slash(link)
      link.sub(/(\/)+$/,'')
    end 
  end
  
  class UserNameFromEmailExtractor
    def initialize(email)
      @email = email
    end
    
    def extract
      if @email.present?
        @email.split("@").first
      end
    end
  end
  
  class Response
    def initialize(response)
      @response = response
    end
    
    def created?
      @response.is_a?(Net::HTTPCreated)
    end
    
    def not_found?
      @response.is_a?(Net::HTTPNotFound)
    end
    
    def wrong_reporter?
       is_failure? && has_error?("reporter")
    end
    
    def wrong_project?
      is_failure? && has_error?("project")
    end
    
    def wrong_issue?
      is_failure? && has_error?("issuetype")
    end
    
    def missing_summary?
      is_failure? && has_error?("summary")
    end 
    
    def error_messages
      body["errors"]
    end
    
    def key
      body["key"]
    end
    
    def body
      @body ||= begin
        JSON.parse(@response.body)
      rescue JSON::ParserError
        {}
      end
    end
    
    private
    def is_failure?
      @response.is_a?(Net::HTTPBadRequest)
    end
    
    def has_error?(name)
      body && body["errors"] && body["errors"][name]
    end
  end

  class Request
    attr_accessor :username, :password
    
    def initialize(url)
      @url = url
    end
    
    def post(fields)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(username, password) if authenticate?
      request.content_type = "application/json"
      request.body = fields.to_json
      response = http.request(request)
      Response.new(response)
    end
    
    def login(username, password)
      self.username, self.password = username, password
      self
    end      
    
    def uri
      url = JiraLinkGenerator.new(@url).api_post_issue
      URI.parse(url)
    end
    
    private         
    def http
      Net::HTTP.new(uri.host, uri.port)
    end
    
    def authenticate?
      username.present? && password.present?
    end
  end
  
  def create_issue(problem, user =  nil)
    response = send_request(problem, user)
    if response.created?
      set_url_to_problem(problem, response.key)
    elsif response.wrong_reporter? && user.present?
      create_issue(problem) # recreate issue without user
    elsif response.not_found?
      raise("Host not found #{request.uri}")
    elsif response.wrong_project?
      raise("Wrong Project")
    elsif response.wrong_issue?
      raise("Wrong Issue Type")
    elsif response.missing_summary?
      raise("Missing summary")
    else
      raise("Something went wrong #{response.error_messages}")  
    end
  end
  
  def check_params
    if Fields.detect {|f| self[f[0]].blank? && !f[1][:optional]}
      errors.add :base, 'You must specify your Domain, Username, Password and Project Key'
    end
  end
  
  def url
    JiraLinkGenerator.new(account).project_page(project_id)
  end
  
  def set_url_to_problem(problem, key)
    problem.update_attributes(
      :issue_link => JiraLinkGenerator.new(account).issue_page(key),
      :issue_type => Label
    )
  end
  
  def send_request(problem, user)
    data = Data.new(project_id, user)
    data.summary = issue_title(problem)
    data.description = body_template.result(binding)
    request.post(data)
  end
  
  def request
    Request.new(account).login(username, password)
  end
  
  def body_template
    @@body_template ||= ERB.new(File.read(Rails.root + "app/views/issue_trackers/textile_body.txt.erb"))
  end
end
