require 'spec_helper'

describe WebMock::HttpLibAdapter do
  describe "adapter_for" do
    it "should add adapter to adapter registry" do
      class MyAdapter < WebMock::HttpLibAdapter; end
      WebMock::HttpLibAdapterRegistry.instance.
        should_receive(:register).with(:my_lib, MyAdapter)
      MyAdapter.adapter_for(:my_lib)
    end
  end
end