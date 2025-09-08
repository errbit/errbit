# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  it { expect(subject).to be_an(ActiveJob::Base) }
end
