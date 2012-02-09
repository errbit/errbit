# Addressable

<dl>
  <dt>Homepage</dt><dd><a href="http://addressable.rubyforge.org/">addressable.rubyforge.org</a></dd>
  <dt>Author</dt><dd><a href="mailto:bob@sporkmonger.com">Bob Aman</a></dd>
  <dt>Copyright</dt><dd>Copyright © 2010 Bob Aman</dd>
  <dt>License</dt><dd>Apache 2.0</dd>
</dl>

# Description

Addressable is a replacement for the URI implementation that is part of
Ruby's standard library. It more closely conforms to the relevant RFCs and
adds support for IRIs and URI templates.  Additionally, it provides extensive
support for URI templates.

# Reference

- {Addressable::URI}
- {Addressable::Template}

# Example usage

    require "addressable/uri"

    uri = Addressable::URI.parse("http://example.com/path/to/resource/")
    uri.scheme
    #=> "http"
    uri.host
    #=> "example.com"
    uri.path
    #=> "/path/to/resource/"

    uri = Addressable::URI.parse("http://www.詹姆斯.com/")
    uri.normalize
    #=> #<Addressable::URI:0xc9a4c8 URI:http://www.xn--8ws00zhy3a.com/>

    require "addressable/template"

    template = Addressable::Template.new("http://example.com/{-list|+|query}/")
    template.expand({
      "query" => "an example query".split(" ")
    })
    #=> #<Addressable::URI:0xc9d95c URI:http://example.com/an+example+query/>

    template = Addressable::Template.new(
      "http://example.com/{-join|&|one,two,three}/"
    )
    template.partial_expand({"one" => "1", "three" => 3}).pattern
    #=> "http://example.com/?one=1{-prefix|&two=|two}&three=3"

    template = Addressable::Template.new(
      "http://{host}/{-suffix|/|segments}?{-join|&|one,two,bogus}\#{fragment}"
    )
    uri = Addressable::URI.parse(
      "http://example.com/a/b/c/?one=1&two=2#foo"
    )
    template.extract(uri)
    #=>
    # {
    #   "host" => "example.com",
    #   "segments" => ["a", "b", "c"],
    #   "one" => "1",
    #   "two" => "2",
    #   "fragment" => "foo"
    # }

# Install

* sudo gem install addressable

You may optionally turn on native IDN support by installing libidn and the
idn gem:

* brew install libidn
* sudo gem install idn
