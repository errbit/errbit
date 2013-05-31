require 'spec_helper'

Fabrication::Config.fabricator_dir.each do |folder|
  Dir.glob(File.join(Rails.root, folder, '**', '*.rb')).each do |file|
    require file
  end
end

describe "Fabrication" do
  Fabrication::Fabricator.schematics.keys.sort.each do |fabricator_name|
    context "Fabricate(:#{fabricator_name})" do
      subject { Fabricate.build(fabricator_name) }

      it { should be_valid }
    end
  end
end
