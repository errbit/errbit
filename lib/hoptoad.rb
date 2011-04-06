module Hoptoad
  module V2
    require 'digest/md5'

    class ApiVersionError < StandardError
      def initialize
        super "Wrong API Version: Expecting v2.0"
      end
    end

    def self.parse_xml(xml)
      parsed  = ActiveSupport::XmlMini.backend.parse(xml)['notice']
      raise ApiVersionError unless parsed && parsed['version'] == '2.0'
      rekeyed = rekey(parsed)
      rekeyed['fingerprint'] = Digest::MD5.hexdigest(rekeyed['error']['backtrace'].to_s)
      rekeyed
    end

    private

      def self.rekey(node)
        if node.is_a?(Hash) && node.has_key?('var') && node.has_key?('key')
          {node['key'] => rekey(node['var'])}
        elsif node.is_a?(Hash) && node.has_key?('var')
          rekey(node['var'])
        elsif node.is_a?(Hash) && node.has_key?('__content__') && node.has_key?('key')
          {node['key'] => node['__content__']}
        elsif node.is_a?(Hash) && node.has_key?('__content__')
          node['__content__']
        elsif node.is_a?(Hash)
          node.inject({}) {|rekeyed, (key,val)|
            rekeyed.merge(key => rekey(val))
          }
        elsif node.is_a?(Array) && node.first.has_key?('key')
          node.inject({}) {|rekeyed,keypair|
            rekeyed.merge(rekey(keypair))
          }
        elsif node.is_a?(Array)
          node.map {|n| rekey(n)}
        else
          node
        end
      end
  end
end
