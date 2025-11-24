# frozen_string_literal: true

require "rails_helper"

Fabrication::Config.fabricator_path.each do |folder|
  Dir.glob(File.join(Rails.root, folder, "**", "*.rb")).each do |file|
    require file
  end
end

RSpec.describe "Fabrication", type: :model do
  # TODO : when 1.8.7 drop support se directly Symbol#sort
  Fabrication.manager.schematics.keys.sort.each do |fabricator_name|
    context "Fabricate(:#{fabricator_name})" do
      subject { Fabricate.build(fabricator_name) }

      it { expect(subject.valid?).to eq(true) }
    end
  end
end
