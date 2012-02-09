# Happymapper patch for RestClient API Change (response => response.body)

module HappyMapper
  module ClassMethods
    alias_method :orig_parse, :parse
    def parse(xml, options={})
      xml = xml.to_s if xml.is_a?(RestClient::Response)
      orig_parse(xml, options)
    end
  end
end