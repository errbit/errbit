require 'spec_helper'

Fabrication::Config.fabricator_path.each do |folder|
  Dir.glob(File.join(Rails.root, folder, '**', '*.rb')).each do |file|
    require file
  end
end

describe "Fabrication" do
  #TODO : when 1.8.7 drop support se directly Symbol#sort
  Fabrication.manager.schematics.keys.sort.each do |fabricator_name|
    context "Fabricate(:#{fabricator_name})" do
      subject { Fabricate.build(fabricator_name) }

      it { should be_valid }
    end
  end
end
