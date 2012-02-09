require 'singleton'

module EmailSpec
  class AddressConverter
    include Singleton
  
    attr_accessor :converter
  
    # The block provided to conversion should convert to an email
    # address string or return the input untouched. For example:
    #
    #  EmailSpec::AddressConverter.instance.conversion do |input|
    #   if input.is_a?(User)
    #     input.email
    #   else
    #     input
    #   end
    #  end
    #    
    def conversion(&block)
      self.converter = block
    end
  
    def convert(input)
      return input unless converter
      converter.call(input)
    end
  end
end