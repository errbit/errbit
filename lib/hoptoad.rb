require 'hoptoad/v2'

module Hoptoad
  class ApiVersionError < StandardError
    def initialize
      super "Wrong API Version: Expecting v2.0"
    end
  end

  def self.parse_xml!(xml)
    xml = xml.unpack('C*').pack('U*')  # Repack string into Unicode to fix invalid UTF-8 chars
    parsed = ActiveSupport::XmlMini.backend.parse(xml)['notice'] || raise(ApiVersionError)
    processor = get_version_processor(parsed['version'])
    processor.process_notice(parsed)
  end

  private
    def self.get_version_processor(version)
      case version
      when '2.0'; Hoptoad::V2
      else;       raise ApiVersionError
      end
    end
end

