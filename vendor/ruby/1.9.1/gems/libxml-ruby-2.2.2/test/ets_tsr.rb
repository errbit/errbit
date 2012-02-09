# encoding: UTF-8

require './test_helper'

10_000.times {|n|
j=XML::Node.new2(nil,"happy#{n}")
  10.times {|r|
    j1=XML::Node.new("happy#{r}","farts")
    j.child=j1
  }
}
