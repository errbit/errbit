require 'spec_helper'

describe WebMock::HttpLibAdapterRegistry do
  describe "each_adapter" do
    it "should yield block over each adapter" do
      class MyAdapter < WebMock::HttpLibAdapter; end
      WebMock::HttpLibAdapterRegistry.instance.register(:my_lib, MyAdapter)
      adapters = []
      WebMock::HttpLibAdapterRegistry.instance.each_adapter {|n,a|
        adapters << [n, a]
      }
      adapters.should include([:my_lib, MyAdapter])
      WebMock::HttpLibAdapterRegistry.instance.
        http_lib_adapters.delete(:my_lib)
    end
  end
end