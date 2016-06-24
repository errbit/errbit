module HashHelper
  def pretty_hash(hash, nesting = 0)
    return '{}' if hash.empty?

    tab_size = 2
    nesting += 1

    pretty  = "{"
    sorted_keys = hash.keys.sort
    sorted_keys.each do |key|
      val = hash[key].is_a?(Hash) ? pretty_hash(hash[key], nesting) : hash[key].inspect
      pretty += "\n#{' ' * nesting * tab_size}"
      pretty += "#{key.inspect} => #{val}"
      pretty += "," unless key == sorted_keys.last
    end
    nesting -= 1
    pretty += "\n#{' ' * nesting * tab_size}}"
  end
end
