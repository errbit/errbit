# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/load" do
  before do
    @original_config = Errbit::Config if Errbit.const_defined?(:Config, false)
  end

  def load_config_with(env)
    allow(ENV).to receive(:[]).and_return(nil)
    {"GITHUB_URL" => "https://github.com"}.merge(env).each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end

    Errbit.send(:remove_const, :Config) if Errbit.const_defined?(:Config, false)
    load Rails.root.join("config/load.rb")
  rescue
    Errbit.const_set(:Config, @original_config) unless Errbit.const_defined?(:Config, false)
    raise
  end

  after do
    Errbit.send(:remove_const, :Config) if Errbit.const_defined?(:Config, false)
    Errbit.const_set(:Config, @original_config) if @original_config
  end

  it "normalizes bracketed notice threshold strings" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => "[1,10,100]",
      "ERRBIT_NOTIFY_AT_NOTICES" => "[0]"
    )

    expect(Errbit::Config.email_at_notices).to eq([1, 10, 100])
    expect(Errbit::Config.notify_at_notices).to eq([0])
  end

  it "normalizes quoted notice threshold strings" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => '"[1,10,100]"',
      "ERRBIT_NOTIFY_AT_NOTICES" => '"[0]"'
    )

    expect(Errbit::Config.email_at_notices).to eq([1, 10, 100])
    expect(Errbit::Config.notify_at_notices).to eq([0])
  end

  it "normalizes comma-separated notice threshold strings" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => '"1, 10, 100"',
      "ERRBIT_NOTIFY_AT_NOTICES" => '"0"'
    )

    expect(Errbit::Config.email_at_notices).to eq([1, 10, 100])
    expect(Errbit::Config.notify_at_notices).to eq([0])
  end

  it "normalizes a single unquoted threshold" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => "1",
      "ERRBIT_NOTIFY_AT_NOTICES" => "0"
    )

    expect(Errbit::Config.email_at_notices).to eq([1])
    expect(Errbit::Config.notify_at_notices).to eq([0])
  end

  it "ignores empty threshold elements" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => '"1,, 10,"',
      "ERRBIT_NOTIFY_AT_NOTICES" => '", 0, "'
    )

    expect(Errbit::Config.email_at_notices).to eq([1, 10])
    expect(Errbit::Config.notify_at_notices).to eq([0])
  end

  it "normalizes empty threshold strings to empty arrays" do
    load_config_with(
      "ERRBIT_EMAIL_AT_NOTICES" => '""',
      "ERRBIT_NOTIFY_AT_NOTICES" => '" "'
    )

    expect(Errbit::Config.email_at_notices).to eq([])
    expect(Errbit::Config.notify_at_notices).to eq([])
  end

  it "rejects invalid threshold values" do
    expect do
      load_config_with("ERRBIT_EMAIL_AT_NOTICES" => '"1,wat,100"')
    end.to raise_error(ArgumentError)
  end
end
