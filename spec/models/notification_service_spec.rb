require 'spec_helper'

describe 'method missing in notifications' do
  let(:service) { Fabricate(:flowdock_notification_service) }
  let(:problem) { Fabricate(:problem) }

  it 'finds a method when called correctly' do
    expect { service.send(:form_message, problem) }.to_not raise_error
  end

  it 'raises a method missing error when the method doesnt exist' do
    expect do
      service.send(:form_dinosaur, problem)
    end.to raise_error(NoMethodError)
  end

end
