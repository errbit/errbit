# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::LocaleMiddleware do
  it "sets the browser locale for a web request and restores it" do
    app = lambda do |_env|
      expect(I18n.locale).to eq(:"pt-BR")
      [200, {}, []]
    end
    request = Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "pt-BR")

    I18n.with_locale(:en) do
      expect(described_class.new(app).call(request)).to eq([200, {"Vary" => "Accept-Language"}, []])
      expect(I18n.locale).to eq(:en)
    end
  end

  it "forces English for API and notifier paths" do
    app = lambda do |_env|
      expect(I18n.locale).to eq(:en)
      [200, {}, []]
    end

    expect(described_class.new(app).call(Rack::MockRequest.env_for("/api/v3/notices", "HTTP_ACCEPT_LANGUAGE" => "pt-BR"))).to eq([200, {}, []])
    expect(described_class.new(app).call(Rack::MockRequest.env_for("/notifier_api/v2/notices", "HTTP_ACCEPT_LANGUAGE" => "pt-BR"))).to eq([200, {}, []])
  end

  it "marks localized responses as varying by Accept-Language" do
    app = ->(_env) { [200, {"Vary" => "Origin"}, []] }

    response = described_class.new(app).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT_LANGUAGE" => "pt-BR"))

    expect(response[1]["Vary"]).to eq("Origin, Accept-Language")
  end
end
