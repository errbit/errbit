class Hash

  # Apply a block to hash, and recursively apply that block
  # to each sub-hash or +types+.
  #
  #   h = {:a=>1, :b=>{:b1=>1, :b2=>2}}
  #   g = h.recurse{|h| h.inject({}){|h,(k,v)| h[k.to_s] = v; h} }
  #   g  #=> {"a"=>1, "b"=>{"b1"=>1, "b2"=>2}}
  #
  def recurse(*types, &block)
    types = [self.class] if types.empty?
    h = inject({}) do |hash, (key, value)|
      case value
      when *types
        hash[key] = value.recurse(*types, &block)
      else
        hash[key] = value
      end
      hash
    end
    yield h
  end

end

