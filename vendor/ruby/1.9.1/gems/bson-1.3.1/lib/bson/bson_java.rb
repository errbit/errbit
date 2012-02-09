include Java
module BSON
  class BSON_JAVA

    # TODO: Pool or cache instances of RubyBSONEncoder so that
    # we don't create a new one on each call to #serialize.
    def self.serialize(obj, check_keys=false, move_id=false)
      raise InvalidDocument, "BSON_JAVA.serialize takes a Hash" unless obj.is_a?(Hash)
      enc = Java::OrgJbson::RubyBSONEncoder.new(JRuby.runtime, check_keys, move_id)
      ByteBuffer.new(enc.encode(obj))
    end

    def self.deserialize(buf)
      dec = Java::OrgJbson::RubyBSONDecoder.new
      callback = Java::OrgJbson::RubyBSONCallback.new(JRuby.runtime)
      dec.decode(buf.to_s.to_java_bytes, callback)
      callback.get
    end

    def self.max_bson_size
      Java::OrgJbson::RubyBSONEncoder.max_bson_size(self)
    end

    def self.update_max_bson_size(connection)
      Java::OrgJbson::RubyBSONEncoder.update_max_bson_size(self, connection)
    end
  end
end
