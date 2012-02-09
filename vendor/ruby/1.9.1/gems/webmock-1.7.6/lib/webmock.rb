require 'singleton'

require 'addressable/uri'
require 'crack'

require 'webmock/deprecation'
require 'webmock/version'

require 'webmock/http_lib_adapters/http_lib_adapter_registry'
require 'webmock/http_lib_adapters/http_lib_adapter'
require 'webmock/http_lib_adapters/net_http'
require 'webmock/http_lib_adapters/httpclient_adapter'
require 'webmock/http_lib_adapters/patron_adapter'
require 'webmock/http_lib_adapters/curb_adapter'
require 'webmock/http_lib_adapters/em_http_request_adapter'
require 'webmock/http_lib_adapters/typhoeus_hydra_adapter'

require 'webmock/errors'

require 'webmock/util/uri'
require 'webmock/util/headers'
require 'webmock/util/hash_counter'
require 'webmock/util/hash_keys_stringifier'
require 'webmock/util/json'

require 'webmock/request_pattern'
require 'webmock/request_signature'
require 'webmock/responses_sequence'
require 'webmock/request_stub'
require 'webmock/response'
require 'webmock/rack_response'

require 'webmock/stub_request_snippet'

require 'webmock/assertion_failure'
require 'webmock/request_execution_verifier'
require 'webmock/config'
require 'webmock/callback_registry'
require 'webmock/request_registry'
require 'webmock/stub_registry'
require 'webmock/api'
require 'webmock/webmock'
