
class Foo

  def zed
    puts "Foo"
  end

end

class Bar < Foo

  def zed(n=nil)
    if n.nil?
      puts "Bar"
    else
      super()
    end
  end

end
