require "heroku/command/base"

# check status of Heroku platform
#
class Heroku::Command::Status < Heroku::Command::Base

  # status
  #
  # display current status of Heroku platform
  #
  def index
    uri = URI.parse('https://status.heroku.com/status.json')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    status = json_decode(response.body)

    display('')
    if status.values.all? {|value| value == 'green'}
      display("All Systems Go: No known issues at this time.")
    else
      status.each do |key, value|
        display("#{key}: #{value}")
      end
      uri = URI.parse('https://status.heroku.com/feed')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)
      entries = REXML::Document.new(response.body).elements.to_a("//entry")
      entry = entries.first
      display('')
      display(entry.elements['title'].text)
      display(entry.elements['content'].text.gsub(/\n\n/, "\n  ").gsub(/<[^>]*>/, ''))
    end
    display('')

  end

end
