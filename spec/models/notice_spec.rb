require 'spec_helper'

describe Notice do
  context 'validations' do
    it 'requires a backtrace' do
      notice = Fabricate.build(:notice, :backtrace => nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:backtrace]).to include("can't be blank")
    end

    it 'requires the server_environment' do
      notice = Fabricate.build(:notice, :server_environment => nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:server_environment]).to include("can't be blank")
    end

    it 'requires the notifier' do
      notice = Fabricate.build(:notice, :notifier => nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:notifier]).to include("can't be blank")
    end
  end

  describe "key sanitization" do
    before do
      @hash = { "some.key" => { "$nested.key" => {"$Path" => "/", "some$key" => "key"}}}
      @hash_sanitized = { "some&#46;key" => { "&#36;nested&#46;key" => {"&#36;Path" => "/", "some$key" => "key"}}}
    end
    [:server_environment, :request, :notifier].each do |key|
      it "replaces . with &#46; and $ with &#36; in keys used in #{key}" do
        err = Fabricate(:err)
        notice = Fabricate(:notice, :err => err, key => @hash)
        expect(notice.send(key)).to eq @hash_sanitized
      end
    end
  end

  describe "user agent" do
    it "should be parsed and human-readable" do
      notice = Fabricate.build(:notice, :request => {'cgi-data' => {
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'
      }})
      expect(notice.user_agent.browser).to eq 'Chrome'
      expect(notice.user_agent.version.to_s).to match( /^10\.0/ )
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = Fabricate.build(:notice)
      expect(notice.user_agent).to eq nil
    end
  end

  describe "user agent string" do
    it "should be parsed and human-readable" do
      notice = Fabricate.build(:notice, :request => {'cgi-data' => {'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'}})
      expect(notice.user_agent_string).to eq 'Chrome 10.0.648.204 (OS X 10.6.7)'
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = Fabricate.build(:notice)
      expect(notice.user_agent_string).to eq "N/A"
    end
  end

  describe "host" do
    it "returns host if url is valid" do
      notice = Fabricate.build(:notice, :request => {'url' => "http://example.com/resource/12"})
      expect(notice.host).to eq 'example.com'
    end

    it "returns 'N/A' when url is not valid" do
      notice = Fabricate.build(:notice, :request => {'url' => "some string"})
      expect(notice.host).to eq 'N/A'
    end

    it "returns 'N/A' when url is empty" do
      notice = Fabricate.build(:notice, :request => {})
      expect(notice.host).to eq 'N/A'
    end
  end

  describe "request" do
    it "returns empty hash if not set" do
      notice = Notice.new
      expect(notice.request).to eq ({})
    end
  end
end
