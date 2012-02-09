require 'ffi'

module BCrypt
  class Engine
    extend FFI::Library

    BCRYPT_MAXSALT = 16
    BCRYPT_SALT_OUTPUT_SIZE = 7 + (BCRYPT_MAXSALT * 4 + 2) / 3 + 1
    BCRYPT_OUTPUT_SIZE = 128

    ffi_lib File.expand_path("../bcrypt_ext", __FILE__)

    attach_function :ruby_bcrypt, [:buffer_out, :string, :string], :string
    attach_function :ruby_bcrypt_gensalt, [:buffer_out, :uint8, :pointer], :string

    def self.__bc_salt(cost, seed)
      buffer_out = FFI::Buffer.alloc_out(BCRYPT_SALT_OUTPUT_SIZE, 1)
      seed_ptr = FFI::MemoryPointer.new(:uint8, BCRYPT_MAXSALT)
      seed.bytes.to_a.each_with_index { |b, i| seed_ptr.int8_put(i, b) }
      out = ruby_bcrypt_gensalt(buffer_out, cost, seed_ptr)
      seed_ptr.free
      buffer_out.free
      out || ""
    end

    def self.__bc_crypt(key, salt, cost)
      buffer_out = FFI::Buffer.alloc_out(BCRYPT_OUTPUT_SIZE, 1)
      out = ruby_bcrypt(buffer_out, key || "", salt)
      buffer_out.free
      out && out.any? ? out : nil
    end
  end
end

