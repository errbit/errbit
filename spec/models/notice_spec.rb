describe Notice, type: 'model' do
  context 'validations' do
    it 'requires a backtrace' do
      notice = Fabricate.build(:notice, backtrace: nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:backtrace_id]).to include("can't be blank")
    end

    it 'requires the server_environment' do
      notice = Fabricate.build(:notice, server_environment: nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:server_environment]).to include("can't be blank")
    end

    it 'requires the notifier' do
      notice = Fabricate.build(:notice, notifier: nil)
      expect(notice).to_not be_valid
      expect(notice.errors[:notifier]).to include("can't be blank")
    end
  end

  describe '#message=' do
    let(:long_message) do
      'Presently I heard a slight groan, and I knew it was the groan of   ' \
      'mortal terror. It was not a groan of pain or of grief --oh, no!    ' \
      '--it was the low stifled sound that arises from the bottom of the  ' \
      'soul when overcharged with awe. I knew the sound well. Many a      ' \
      'night, just at midnight, when all the world slept, it has welled   ' \
      'up from my own bosom, deepening, with its dreadful echo, the       ' \
      'terrors that distracted me. I say I knew it well. I knew what the  ' \
      'old man felt, and pitied him, although I chuckled at heart. I      ' \
      'knew that he had been lying awake ever since the first slight      ' \
      'noise, when he had turned in the bed. His fears had been ever      ' \
      'since growing upon him. He had been trying to fancy them           ' \
      'causeless, but could not. He had been saying to himself --"It is   ' \
      'nothing but the wind in the chimney --it is only a mouse crossing  ' \
      'the floor," or "It is merely a cricket which has made a single     ' \
      'chirp." Yes, he had been trying to comfort himself with these      ' \
      'suppositions: but he had found all in vain. All in vain; because   ' \
      'Death, in approaching him had stalked with his black shadow        ' \
      'before him, and enveloped the victim. And it was the mournful      ' \
      'influence of the unperceived shadow that caused him to feel        ' \
      '--although he neither saw nor heard --to feel the presence of my   ' \
      'head within the room.                                              '
    end

    it 'truncates the message' do
      notice = Fabricate(:notice, message: long_message)
      expect(long_message.length).to be > 1000
      expect(notice.message.length).to eq 1000
    end
  end

  describe "key sanitization" do
    before do
      @hash = { "some.key" => { "$nested.key" => { "$Path" => "/", "some$key" => "key" } } }
      @hash_sanitized = { "some&#46;key" => { "&#36;nested&#46;key" => { "&#36;Path" => "/", "some$key" => "key" } } }
    end
    [:server_environment, :request, :notifier].each do |key|
      it "replaces . with &#46; and $ with &#36; in keys used in #{key}" do
        err = Fabricate(:err)
        notice = Fabricate(:notice, :err => err, key => @hash)
        expect(notice.send(key)).to eq @hash_sanitized
      end
    end
  end

  describe "to_curl" do
    let(:notice)  { Fabricate.build(:notice, request: request) }

    context "when it has a request url" do
      let(:request) { { 'url' => "http://example.com/resource/12", 'cgi-data' => { 'HTTP_USER_AGENT' => 'Mozilla/5.0' } } }

      it 'has a curl representation' do
        cmd = notice.to_curl
        expect(cmd).to eq("curl -X GET -H 'User-Agent: Mozilla/5.0' http://example.com/resource/12")
      end
    end

    context "when it has not a request url" do
      let(:request) { { 'cgi-data' => { 'HTTP_USER_AGENT' => 'Mozilla/5.0' } } }

      it 'has a curl representation' do
        cmd = notice.to_curl
        expect(cmd).to eq "N/A"
      end
    end
  end

  describe "user agent" do
    it "should be parsed and human-readable" do
      notice = Fabricate.build(:notice, request: { 'cgi-data' => {
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16'
      } })
      expect(notice.user_agent.browser).to eq 'Chrome'
      expect(notice.user_agent.version.to_s).to match(/^10\.0/)
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = Fabricate.build(:notice)
      expect(notice.user_agent).to eq nil
    end
  end

  describe "user agent string" do
    it "should be parsed and human-readable" do
      notice = Fabricate.build(:notice, request: { 'cgi-data' => { 'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16' } })
      expect(notice.user_agent_string).to eq 'Chrome 10.0.648.204 (OS X 10.6.7)'
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = Fabricate.build(:notice)
      expect(notice.user_agent_string).to eq "N/A"
    end
  end

  describe "host" do
    it "returns host if url is valid" do
      notice = Fabricate.build(:notice, request: { 'url' => "http://example.com/resource/12" })
      expect(notice.host).to eq 'example.com'
    end

    it "returns 'N/A' when url is not valid" do
      notice = Fabricate.build(:notice, request: { 'url' => "file:///path/to/some/resource/12" })
      expect(notice.host).to eq 'N/A'
    end

    it "returns 'N/A' when url is not valid" do
      notice = Fabricate.build(:notice, request: { 'url' => "some string" })
      expect(notice.host).to eq 'N/A'
    end

    it "returns 'N/A' when url is empty" do
      notice = Fabricate.build(:notice, request: {})
      expect(notice.host).to eq 'N/A'
    end
  end

  describe "request" do
    it "returns empty hash if not set" do
      notice = Notice.new
      expect(notice.request).to eq({})
    end
  end

  describe "env_vars" do
    it "returns the cgi-data" do
      notice = Notice.new
      notice.request = { 'cgi-data' => { 'ONE' => 'TWO' } }
      expect(notice.env_vars).to eq('ONE' => 'TWO')
    end

    it "always returns a hash" do
      notice = Notice.new
      notice.request = { 'cgi-data' => [] }
      expect(notice.env_vars).to eq({})
    end
  end
end
