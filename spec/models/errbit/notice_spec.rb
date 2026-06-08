# frozen_string_literal: true

require "rails_helper"

RSpec.describe Errbit::Notice, type: :model do
  it "inherits from Errbit::ApplicationRecord" do
    expect(described_class.ancestors).to include(Errbit::ApplicationRecord)
  end

  it "uses the errbit_notices table" do
    expect(described_class.table_name).to eq("errbit_notices")
  end

  context "validations" do
    it "requires a backtrace" do
      notice = build(:errbit_notice, backtrace: nil)

      expect(notice.valid?).to eq(false)
      expect(notice.errors[:backtrace]).to include("must exist")
    end

    it "requires an app" do
      notice = build(:errbit_notice, app: nil)

      expect(notice.valid?).to eq(false)
      expect(notice.errors[:app]).to include("must exist")
    end

    it "requires an err" do
      notice = build(:errbit_notice, err: nil)

      expect(notice.valid?).to eq(false)
      expect(notice.errors[:err]).to include("must exist")
    end

    it "requires server_environment" do
      notice = build(:errbit_notice, server_environment: nil)

      expect(notice.valid?).to eq(false)
      expect(notice.errors[:server_environment]).to include("can't be blank")
    end

    it "requires notifier" do
      notice = build(:errbit_notice, notifier: nil)

      expect(notice.valid?).to eq(false)
      expect(notice.errors[:notifier]).to include("can't be blank")
    end
  end

  describe "#message=" do
    let(:long_message) { "x" * (described_class::MESSAGE_LENGTH_LIMIT * 2) }

    it "truncates the message" do
      notice = create(:errbit_notice, message: long_message)

      expect(long_message.length).to be > described_class::MESSAGE_LENGTH_LIMIT
      expect(notice.message.length).to eq(described_class::MESSAGE_LENGTH_LIMIT)
    end

    it "truncates a long multibyte message by bytes" do
      long_mb_message = "ä" * (described_class::MESSAGE_LENGTH_LIMIT)
      notice = create(:errbit_notice, message: long_mb_message)

      expect(long_mb_message.bytesize).to be > described_class::MESSAGE_LENGTH_LIMIT
      expect(notice.message.bytesize).to be <= described_class::MESSAGE_LENGTH_LIMIT
    end
  end

  describe "key sanitization" do
    let(:hash) { {"some.key" => {"$nested.key" => {"$Path" => "/", "some$key" => "key"}}} }
    let(:hash_sanitized) { {"some&#46;key" => {"&#36;nested&#46;key" => {"&#36;Path" => "/", "some$key" => "key"}}} }

    [:server_environment, :request, :notifier].each do |key|
      it "replaces . with &#46; and $ with &#36; in keys used in #{key}" do
        notice = create(:errbit_notice, key => hash)

        expect(notice.send(key)).to eq(hash_sanitized)
      end
    end
  end

  describe "#user_agent" do
    it "parses a known user agent string" do
      notice = build(:errbit_notice, request: {"cgi-data" => {
        "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16"
      }})

      expect(notice.user_agent.browser).to eq("Chrome")
      expect(notice.user_agent.version.to_s).to match(/^10\.0/)
    end

    it "returns nil when HTTP_USER_AGENT is blank" do
      notice = build(:errbit_notice)

      expect(notice.user_agent).to be_nil
    end
  end

  describe "#user_agent_string" do
    it "returns a human-readable user agent" do
      notice = build(:errbit_notice, request: {"cgi-data" => {
        "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16"
      }})

      expect(notice.user_agent_string).to eq("Chrome 10.0.648.204 (OS X 10.6.7)")
    end

    it "returns 'N/A' when HTTP_USER_AGENT is blank" do
      notice = build(:errbit_notice)

      expect(notice.user_agent_string).to eq(described_class::UNAVAILABLE)
    end
  end

  describe "#host" do
    it "returns the host when url is valid" do
      notice = build(:errbit_notice, request: {"url" => "http://example.com/resource/12"})

      expect(notice.host).to eq("example.com")
    end

    it "returns 'N/A' when url has no host" do
      notice = build(:errbit_notice, request: {"url" => "file:///path/to/some/resource/12"})

      expect(notice.host).to eq("N/A")
    end

    it "returns 'N/A' when url is unparseable" do
      notice = build(:errbit_notice, request: {"url" => "some string"})

      expect(notice.host).to eq("N/A")
    end

    it "returns 'N/A' when url is missing" do
      notice = build(:errbit_notice, request: {})

      expect(notice.host).to eq("N/A")
    end
  end

  describe "#request" do
    it "returns an empty hash when not set" do
      expect(described_class.new.request).to eq({})
    end
  end

  describe "#env_vars" do
    it "returns the cgi-data hash" do
      notice = described_class.new
      notice.request = {"cgi-data" => {"ONE" => "TWO"}}

      expect(notice.env_vars).to eq("ONE" => "TWO")
    end

    it "returns an empty hash when cgi-data is not a hash" do
      notice = described_class.new
      notice.request = {"cgi-data" => []}

      expect(notice.env_vars).to eq({})
    end
  end

  describe "#environment_name" do
    it "returns server-environment when present" do
      notice = build(:errbit_notice, server_environment: {"server-environment" => "staging"})

      expect(notice.environment_name).to eq("staging")
    end

    it "falls back to environment-name" do
      notice = build(:errbit_notice, server_environment: {"environment-name" => "production"})

      expect(notice.environment_name).to eq("production")
    end

    it "defaults to development when both are blank" do
      notice = build(:errbit_notice, server_environment: {"server-environment" => ""})

      expect(notice.environment_name).to eq("development")
    end
  end

  describe "#where" do
    it "joins component and action with #" do
      notice = build(:errbit_notice, request: {"component" => "users", "action" => "show"})

      expect(notice.where).to eq("users#show")
    end

    it "returns just component when action is blank" do
      notice = build(:errbit_notice, request: {"component" => "users"})

      expect(notice.where).to eq("users")
    end
  end

  describe "#filtered_message" do
    it "removes memory addresses from object strings" do
      notice = build(:errbit_notice, message: "#<Object:0x007fa2b33d9458>")

      expect(notice.filtered_message).to eq("#<Object>")
    end
  end

  describe "scopes" do
    describe ".ordered" do
      it "orders by created_at asc" do
        older = create(:errbit_notice, created_at: 2.days.ago)
        newer = create(:errbit_notice, created_at: 1.minute.ago)

        ordered = described_class.ordered.to_a

        expect(ordered.index(older)).to be < ordered.index(newer)
      end
    end

    describe ".reverse_ordered" do
      it "orders by created_at desc" do
        older = create(:errbit_notice, created_at: 2.days.ago)
        newer = create(:errbit_notice, created_at: 1.minute.ago)

        ordered = described_class.reverse_ordered.to_a

        expect(ordered.index(newer)).to be < ordered.index(older)
      end
    end

    describe ".for_errs" do
      it "returns notices belonging to the given errs" do
        err = create(:errbit_err)
        notice = create(:errbit_notice, err: err)
        create(:errbit_notice)

        expect(described_class.for_errs([err]).to_a).to eq([notice])
      end
    end
  end

  describe "delegation" do
    it "delegates problem to err" do
      problem = create(:errbit_problem)
      err = create(:errbit_err, problem: problem)
      notice = create(:errbit_notice, err: err)

      expect(notice.problem).to eq(problem)
    end

    it "delegates backtrace_lines to backtrace" do
      backtrace = create(:errbit_backtrace)
      notice = create(:errbit_notice, backtrace: backtrace)

      expect(notice.backtrace_lines).to eq(backtrace.lines)
    end
  end
end
