module HashHelper

  def pretty_hash(hash, nesting = 0)
    tab_size = 2
    nesting += 1

    pretty  = "{"
    sorted_keys = hash.keys.sort
    sorted_keys.each do |key|
      if hash[key].is_a?(Hash)
        val = pretty_hash(hash[key], nesting)
      elsif hash[key].is_a?(Array)
        val = pretty_array(hash[key], nesting)
      else
        val = hash[key].to_s
      end
      pretty += "\n#{' '*nesting*tab_size}"
      pretty += "#{key.inspect} => #{val}"
      pretty += "," unless key == sorted_keys.last

    end
    nesting -= 1
    pretty += "\n#{' '*nesting*tab_size}}"
  end

  def pretty_array(array, nesting = 0)
    nesting += 1
    pretty  = "["
    array.each do |element|
      if element.is_a?(Hash)
        val = pretty_hash(element, nesting)
      elsif element.is_a?(Array)
        val = pretty_array(element, nesting)
      else
        val = element.to_s
      end
      pretty += val
      if array.last != element
        pretty += ", "
      end
    end
    nesting -= 1
    pretty += "]"
  end

end
