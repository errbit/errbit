require 'spec_helper'

describe BacktraceLine do
  subject { described_class.new(raw_line) }

  describe "root at the start of decorated filename" do
    let(:raw_line) { { 'number' => rand(999), 'file' => '[PROJECT_ROOT]/app/controllers/pages_controller.rb', 'method' => ActiveSupport.methods.shuffle.first.to_s } }
    it "should leave leading root symbol in filepath" do
      subject.decorated_path.should == 'app/controllers/'
    end
  end
end
