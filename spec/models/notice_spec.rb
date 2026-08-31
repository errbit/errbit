# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice, type: :model do
  context "validations" do
    it "requires a backtrace" do
      notice = build(:notice, backtrace: nil)
      expect(notice.valid?).to eq(false)
      expect(notice.errors[:backtrace_id]).to include("can't be blank")
    end

    it "requires the server_environment" do
      notice = build(:notice, server_environment: nil)
      expect(notice.valid?).to eq(false)
      expect(notice.errors[:server_environment]).to include("can't be blank")
    end

    it "requires the notifier" do
      notice = build(:notice, notifier: nil)
      expect(notice.valid?).to eq(false)
      expect(notice.errors[:notifier]).to include("can't be blank")
    end
  end

  describe "#message=" do
    let(:long_message) do
      "Presently I heard a slight groan, and I knew it was the groan of   " \
      "mortal terror. It was not a groan of pain or of grief --oh, no!    " \
      "--it was the low stifled sound that arises from the bottom of the  " \
      "soul when overcharged with awe. I knew the sound well. Many a      " \
      "night, just at midnight, when all the world slept, it has welled   " \
      "up from my own bosom, deepening, with its dreadful echo, the       " \
      "terrors that distracted me. I say I knew it well. I knew what the  " \
      "old man felt, and pitied him, although I chuckled at heart. I      " \
      "knew that he had been lying awake ever since the first slight      " \
      "noise, when he had turned in the bed. His fears had been ever      " \
      "since growing upon him. He had been trying to fancy them           " \
      'causeless, but could not. He had been saying to himself --"It is   ' \
      "nothing but the wind in the chimney --it is only a mouse crossing  " \
      'the floor," or "It is merely a cricket which has made a single     ' \
      'chirp." Yes, he had been trying to comfort himself with these      ' \
      "suppositions: but he had found all in vain. All in vain; because   " \
      "Death, in approaching him had stalked with his black shadow        " \
      "before him, and enveloped the victim. And it was the mournful      " \
      "influence of the unperceived shadow that caused him to feel        " \
      "--although he neither saw nor heard --to feel the presence of my   " \
      "head within the room.                                              "
    end

    it "truncates the message" do
      notice = create(:notice, message: long_message)
      expect(long_message.length).to be > Notice::MESSAGE_LENGTH_LIMIT
      expect(notice.message.length).to eq(Notice::MESSAGE_LENGTH_LIMIT)
    end

    let(:long_mb_message) do
      "Elasticsearch::Transport::Transport::Errors::InternalServerError: " \
      '[500] {"error":"SearchPhaseExecutionException[Failed to execute phase ' \
      "[query_fetch], all shards failed; shardFailures {[abc][test][0]: " \
      "QueryPhaseExecutionException[[test][0]: query[function score " \
      "(_all:t4t44äöäöäööäöäöäöäöäälüöläpläfdälfäpdlsfaäpldspsadpfäsdkfasdö" \
      "äkfadsökfjaädsfjsdaäfjadsklfldslsäfjkläsdajfläaslhfldskhfasljdhfl444" \
      "44t44t4t4t4t44t4444tt444tt4þt444t4gt4t444t44t444g4444t4g44g4tt444g44" \
      "44tgt444ggþ444þ4t4þ4t44444t4444g4444t44gþt4t4tþg4t44t4t4444gt44t444t" \
      "4t4t444tt44t44þt4t4þt4444444þgþ4tt4t4g444gt4t4t444þ44g4t44g4tgþ4t4t4" \
      "44t4þþ444t44t4t44~2,function=script[_score * _source.boost], params " \
      "[null])],from[0],size[10]: Query Failed [Failed to execute main " \
      "query]]; nested: RuntimeException[org.apache.lucene.util.automaton." \
      "TooComplexToDeterminizeException: Determinizing automaton would " \
      "result in more than 10000 states.]; nested: TooComplexToDeterminize" \
      "Exception[Determinizing automaton would result in more than 10000 " \
      'states.]; }]","status":500}'
    end

    it "truncates the long multibyte string message" do
      notice = create(:notice, message: long_mb_message)
      expect(long_mb_message.bytesize).to be > Notice::MESSAGE_LENGTH_LIMIT
      expect(notice.message.bytesize).to eq(Notice::MESSAGE_LENGTH_LIMIT)
    end
  end

  describe "key sanitization" do
    before do
      @hash = {"some.key" => {"$nested.key" => {"$Path" => "/", "some$key" => "key"}}}
      @hash_sanitized = {"some&#46;key" => {"&#36;nested&#46;key" => {"&#36;Path" => "/", "some$key" => "key"}}}
    end

    [:server_environment, :request, :notifier, :user_attributes].each do |key|
      it "replaces . with &#46; and $ with &#36; in keys used in #{key}" do
        err = create(:err)
        notice = create(:notice, err: err, "#{key}": @hash)
        expect(notice.send(key)).to eq(@hash_sanitized)
      end
    end

    it "normalizes symbol keys to strings" do
      notice = create(:notice, request: {
        password: "secret",
        safe_key: "value"
      })

      expect(notice.request).to eq(
        "password" => Notice::FILTERED_TEXT,
        "safe_key" => "value"
      )
    end
  end

  describe "sensitive request data sanitization" do
    it "uses the app setting when it overrides the global setting" do
      allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)
      app = create(:app, sanitize_notice_data: true)
      notice = create(:notice, app: app, request: {"params" => {"password" => "secret"}})

      expect(notice.params["password"]).to eq(Notice::FILTERED_TEXT)
    end

    it "uses the global setting when the app inherits it" do
      allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)
      app = create(:app, sanitize_notice_data: nil)
      notice = create(:notice, app: app, request: {"params" => {"password" => "secret"}})

      expect(notice.params["password"]).to eq("secret")
    end

    it "uses the app setting when it disables sanitization" do
      allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(true)
      app = create(:app, sanitize_notice_data: false)
      notice = create(:notice, app: app, request: {"params" => {"password" => "secret"}})

      expect(notice.params["password"]).to eq("secret")
    end

    it "redacts sensitive data and preserves safe request metadata" do
      notice = create(:notice,
        server_environment: {
          "environment-name" => "production",
          "secret_key_base" => "secret",
          "session" => "secret"
        },
        notifier: {
          "name" => "Notifier",
          "authorization" => "secret"
        },
        user_attributes: {
          "id" => "user-42",
          "api_token" => "secret"
        },
        request: {
          "url" => "https://example.test/path?user_id=42&password=secret",
          "cgi-data" => {
            "REQUEST_METHOD" => "GET",
            "PATH_INFO" => "/path",
            "QUERY_STRING" => "user_id=42&password=secret",
            "HTTP_HOST" => "example.test",
            "HTTP_COOKIE" => "session=secret",
            "HTTP_AUTHORIZATION" => "Bearer secret",
            "action_dispatch_secret_key_base" => "secret",
            "action_dispatch_request_id" => "request-id",
            "rack.input" => "internal",
            "rack.errors" => "internal",
            "puma.socket" => "internal",
            "custom_data" => {
              "some.key" => {"safe" => "value"},
              "secret_token" => "secret"
            }
          },
          "params" => {
            "user_id" => 42,
            "password" => "secret",
            "nested" => {"api_key" => "secret", "safe" => "value"},
            "tokenizer" => "diagnostic text",
            "certificate_status" => "valid",
            "cookie_consent" => true,
            "session_count" => 2
          },
          "session" => {"locale" => "en", "_csrf_token" => "secret"}
        })

      expect(notice.request).to include(
        "url" => "https://example.test/path?user_id=42&password=%5BFILTERED%5D",
        "params" => {
          "user_id" => 42,
          "password" => Notice::FILTERED_TEXT,
          "nested" => {"api_key" => Notice::FILTERED_TEXT, "safe" => "value"},
          "tokenizer" => Notice::FILTERED_TEXT,
          "certificate_status" => Notice::FILTERED_TEXT,
          "cookie_consent" => Notice::FILTERED_TEXT,
          "session_count" => Notice::FILTERED_TEXT
        }
      )
      expect(notice.session).to eq("locale" => "en", "_csrf_token" => Notice::FILTERED_TEXT)
      expect(notice.env_vars).to include(
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/path",
        "HTTP_HOST" => "example.test"
      )
      expect(notice.env_vars["HTTP_COOKIE"]).to eq(Notice::FILTERED_TEXT)
      expect(notice.env_vars["HTTP_AUTHORIZATION"]).to eq(Notice::FILTERED_TEXT)
      expect(notice.env_vars).not_to have_key("action_dispatch_secret_key_base")
      expect(notice.env_vars).not_to have_key("rack.input")
      expect(notice.env_vars).not_to have_key("rack.errors")
      expect(notice.env_vars).not_to have_key("puma.socket")
      expect(notice.env_vars["custom_data"]).to eq(
        "some&#46;key" => {"safe" => "value"},
        "secret_token" => Notice::FILTERED_TEXT
      )
      expect(notice.env_vars["QUERY_STRING"]).to eq("user_id=42&password=%5BFILTERED%5D")
      expect(notice.server_environment).to include("secret_key_base" => Notice::FILTERED_TEXT, "session" => Notice::FILTERED_TEXT)
      expect(notice.notifier).to eq("name" => "Notifier", "authorization" => Notice::FILTERED_TEXT)
      expect(notice.user_attributes).to eq("id" => "user-42", "api_token" => Notice::FILTERED_TEXT)
    end

    it "redacts configured sensitive keys without replacing built-in filtering" do
      allow(Errbit::Config).to receive(:sensitive_keys).and_return("customer_ssn,private_id")
      notice = create(:notice,
        server_environment: {"environment-name" => "production", "customer_ssn" => "secret"},
        notifier: {"name" => "Notifier", "private_id" => "secret"},
        user_attributes: {"id" => "user-42", "CUSTOMER_SSN" => "secret"},
        request: {
          "params" => {"private_id" => "secret", "password" => "secret"},
          "session" => {"customer_ssn" => "secret", "locale" => "en"},
          "cgi-data" => {"PRIVATE_ID" => "secret"}
        })

      expect(notice.server_environment["customer_ssn"]).to eq(Notice::FILTERED_TEXT)
      expect(notice.notifier["private_id"]).to eq(Notice::FILTERED_TEXT)
      expect(notice.user_attributes["CUSTOMER_SSN"]).to eq(Notice::FILTERED_TEXT)
      expect(notice.params).to eq("private_id" => Notice::FILTERED_TEXT, "password" => Notice::FILTERED_TEXT)
      expect(notice.session).to eq("customer_ssn" => Notice::FILTERED_TEXT, "locale" => "en")
      expect(notice.env_vars["PRIVATE_ID"]).to eq(Notice::FILTERED_TEXT)
    end

    it "matches configured sensitive keys literally and case-insensitively" do
      allow(Errbit::Config).to receive(:sensitive_keys).and_return("customer_identifier")
      notice = create(:notice, request: {
        "params" => {
          "CUSTOMER_IDENTIFIER" => "secret",
          "customer_identifier_note" => "safe diagnostic"
        }
      })

      expect(notice.params).to eq(
        "CUSTOMER_IDENTIFIER" => Notice::FILTERED_TEXT,
        "customer_identifier_note" => "safe diagnostic"
      )
    end

    it "treats request session keys case-insensitively as containers" do
      ["session", "Session", "SESSION"].each do |session_key|
        notice = create(:notice, request: {
          session_key => {"locale" => "en", "csrf_token" => "secret"}
        })

        expect(notice.request[session_key]).to eq(
          "locale" => "en",
          "csrf_token" => Notice::FILTERED_TEXT
        )
      end
    end

    it "redacts non-container session values" do
      notice = create(:notice, request: {"session" => "raw-secret"})

      expect(notice.request["session"]).to eq(Notice::FILTERED_TEXT)
    end

    it "retains legacy data when privacy sanitization is disabled" do
      allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)
      allow(Errbit::Config).to receive(:sensitive_keys).and_return("private_id")
      notice = create(:notice,
        server_environment: {"environment-name" => "production", "secret_key_base" => "secret"},
        notifier: {"name" => "Notifier", "authorization" => "secret"},
        user_attributes: {"id" => "user-42", "api_token" => "secret"},
        request: {
          "url" => "https://user:password@example.test/path?password=secret#access-token",
          "params" => {"password" => "secret", "private_id" => "secret"},
          "session" => {"csrf_token" => "secret", "locale" => "en"},
          "cgi-data" => {
            "rack.input" => "internal",
            "QUERY_STRING" => "password=secret",
            "some.key" => "value"
          }
        })

      expect(notice.server_environment["secret_key_base"]).to eq("secret")
      expect(notice.notifier["authorization"]).to eq("secret")
      expect(notice.user_attributes["api_token"]).to eq("secret")
      expect(notice.request["url"]).to eq("https://user:password@example.test/path?password=secret#access-token")
      expect(notice.params["password"]).to eq("secret")
      expect(notice.params["private_id"]).to eq("secret")
      expect(notice.session).to eq("csrf_token" => "secret", "locale" => "en")
      expect(notice.env_vars["rack&#46;input"]).to eq("internal")
      expect(notice.env_vars["QUERY_STRING"]).to eq("password=secret")
      expect(notice.env_vars["some&#46;key"]).to eq("value")
    end

    it "keeps MongoDB key escaping and invalid string handling when privacy sanitization is disabled" do
      allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)
      invalid_value = "\xAD".b.force_encoding(Encoding::UTF_8)
      notice = create(:notice, request: {
        "some.key" => invalid_value,
        "$nested" => {"key.with.dot" => "value"}
      })

      expect(notice.request["some&#46;key"]).to be_nil
      expect(notice.request["&#36;nested"]).to eq("key&#46;with&#46;dot" => "value")
    end

    it "drops malformed query strings instead of persisting their bytes" do
      [
        "%ADd+auto_prepend_file=php://input",
        "foo=%",
        "foo=%Z",
        "foo=%ZZ",
        "foo=%C3"
      ].each do |query|
        notice = create(:notice, request: {
          "url" => "https://example.test/?#{query}",
          "cgi-data" => {
            "QUERY_STRING" => query,
            "REQUEST_URI" => "/?#{query}"
          }
        })

        expect(notice.request["url"]).to eq("https://example.test/")
        expect(notice.env_vars["QUERY_STRING"]).to be_nil
        expect(notice.env_vars["REQUEST_URI"]).to eq("/")
      end
    end

    it "sanitizes query keys, duplicate values, spaces, and fragments" do
      notice = create(:notice, request: {
        "url" => "https://example.test/path?name=John%20Doe&pass%77ord=secret&id=1&id=2#access-token",
        "cgi-data" => {
          "QUERY_STRING" => "name=John+Doe&pass%77ord=secret&id=1&id=2#fragment",
          "REQUEST_URI" => "/path?name=John+Doe&pass%77ord=secret&id=1&id=2#fragment"
        }
      })

      filtered_query = "name=John+Doe&password=%5BFILTERED%5D&id=1&id=2"
      expect(notice.request["url"]).to eq("https://example.test/path?#{filtered_query}")
      expect(notice.env_vars["QUERY_STRING"]).to eq(filtered_query)
      expect(notice.env_vars["REQUEST_URI"]).to eq("/path?#{filtered_query}")
    end

    it "applies configured sensitive keys to decoded query-string keys" do
      allow(Errbit::Config).to receive(:sensitive_keys).and_return("customer_identifier")
      notice = create(:notice, request: {
        "url" => "https://example.test/?customer%5Fidentifier=secret&safe=value",
        "cgi-data" => {"QUERY_STRING" => "customer%5Fidentifier=secret&safe=value"}
      })

      expect(notice.request["url"]).to eq("https://example.test/?customer_identifier=%5BFILTERED%5D&safe=value")
      expect(notice.env_vars["QUERY_STRING"]).to eq("customer_identifier=%5BFILTERED%5D&safe=value")
    end

    it "preserves valid UTF-8 percent-encoded multi-byte sequences in query strings" do
      notice = create(:notice, request: {
        "url" => "https://example.test/path?search=%C3%A9",
        "cgi-data" => {
          "QUERY_STRING" => "search=%C3%A9",
          "REQUEST_URI" => "/path?search=%C3%A9",
          "ORIGINAL_FULLPATH" => "/path?search=%C3%A9"
        }
      })

      expect(notice.request["url"]).to eq("https://example.test/path?search=%C3%A9")
      expect(notice.env_vars["QUERY_STRING"]).to eq("search=%C3%A9")
      expect(notice.env_vars["REQUEST_URI"]).to eq("/path?search=%C3%A9")
      expect(notice.env_vars["ORIGINAL_FULLPATH"]).to eq("/path?search=%C3%A9")
    end

    it "removes userinfo and fragments from URLs" do
      notice = create(:notice, request: {
        "url" => "https://user:password@example.test/path?next=%2Fhome#access-token"
      })

      expect(notice.request["url"]).to eq("https://example.test/path?next=%2Fhome")
    end

    it "drops raw invalid UTF-8 from URL-like fields" do
      invalid_url = "\xAD".b.force_encoding(Encoding::UTF_8)
      notice = create(:notice, request: {
        "url" => invalid_url,
        "cgi-data" => {
          "REQUEST_URI" => invalid_url,
          "ORIGINAL_FULLPATH" => invalid_url
        }
      })

      expect(notice.request["url"]).to be_nil
      expect(notice.env_vars["REQUEST_URI"]).to be_nil
      expect(notice.env_vars["ORIGINAL_FULLPATH"]).to be_nil
    end
  end

  describe "user agent" do
    it "should be parsed and human-readable" do
      notice = build(:notice, request: {"cgi-data" => {
        "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16"
      }})
      expect(notice.user_agent.browser).to eq("Chrome")
      expect(notice.user_agent.version.to_s).to match(/^10\.0/)
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = build(:notice)
      expect(notice.user_agent).to eq(nil)
    end
  end

  describe "user agent string" do
    it "should be parsed and human-readable" do
      notice = build(:notice, request: {"cgi-data" => {"HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_7; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.204 Safari/534.16"}})

      expect(notice.user_agent_string).to eq("Chrome 10.0.648.204 (OS X 10.6.7)")
    end

    it "should be nil if HTTP_USER_AGENT is blank" do
      notice = build(:notice)

      expect(notice.user_agent_string).to eq("N/A")
    end
  end

  describe "host" do
    it "returns host if url is valid" do
      notice = build(:notice, request: {"url" => "http://example.com/resource/12"})

      expect(notice.host).to eq("example.com")
    end

    it "returns 'N/A' when url is not valid" do
      notice = build(:notice, request: {"url" => "file:///path/to/some/resource/12"})

      expect(notice.host).to eq("N/A")
    end

    it "returns 'N/A' when url is not valid" do
      notice = build(:notice, request: {"url" => "some string"})

      expect(notice.host).to eq("N/A")
    end

    it "returns 'N/A' when url is empty" do
      notice = build(:notice, request: {})

      expect(notice.host).to eq("N/A")
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

      notice.request = {"cgi-data" => {"ONE" => "TWO"}}

      expect(notice.env_vars).to eq("ONE" => "TWO")
    end

    it "always returns a hash" do
      notice = Notice.new

      notice.request = {"cgi-data" => []}

      expect(notice.env_vars).to eq({})
    end
  end
end
