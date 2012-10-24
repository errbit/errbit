require 'spec_helper'

describe Err do
  it 'sets a default error_class and environment' do
    err = Err.new
    err.error_class.should == "UnknownError"
    err.environment.should == "unknown"
  end
end

