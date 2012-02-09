require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestLinks < Test::Unit::TestCase
  def test_empty_query_string
    assert_nothing_raised do
      premailer = Premailer.new('<p>Test</p>', :with_html_string => true, :link_query_string => ' ')
      premailer.to_inline_css
    end
  end

  def test_appending_link_query_string
    qs = 'utm_source=1234&tracking=good&amp;doublescape'
    opts = {:base_url => 'http://example.com/',  :link_query_string => qs, :with_html_string => true, :adapter => :hpricot}
    
    appendable = [
      '/', 
      opts[:base_url], 
      'https://example.com/tester',
      'images/',
      "#{opts[:base_url]}test.html?cn=tf&amp;c=20&amp;ord=random",
      '?query=string'
    ]
      
    not_appendable = [
      '%DONOTCONVERT%',
      '{DONOTCONVERT}',
      '[DONOTCONVERT]',
      '<DONOTCONVERT>',
      '{@msg-txturl}',
      '[[!unsubscribe]]',
      '#relative', 
      'tel:5555551212',
      'http://example.net/',
      'mailto:premailer@example.com',
      'ftp://example.com',
      'gopher://gopher.floodgap.com/1/fun/twitpher'
    ]
    
    html = appendable.collect {|url| "<a href='#{url}'>Link</a>" }

    premailer = Premailer.new(html.to_s, opts)
    premailer.to_inline_css
    
    premailer.processed_doc.search('a').each do |el|
      href = el.attributes['href'].to_s
      next if href.nil? or href.empty?
      uri = URI.parse(href)
      assert_match qs, uri.query, "missing query string for #{el.to_s}"
    end

    html = not_appendable.collect {|url| "<a href='#{url}'>Link</a>" }

    premailer = Premailer.new(html.to_s, opts)
    premailer.to_inline_css
    
    premailer.processed_doc.search('a').each do |el|
      href = el['href']
      next if href.nil? or href.empty?
      assert not_appendable.include?(href), "link #{href} should not be converted: see #{not_appendable.to_s}"
    end
  end

  def test_stripping_extra_question_marks_from_query_string
    qs = '??utm_source=1234'

    premailer = Premailer.new("<a href='/test/?'>Link</a> <a href='/test/'>Link</a>", :link_query_string => qs, :with_html_string => true)
    premailer.to_inline_css
    
    premailer.processed_doc.search('a').each do |a|
      assert_equal '/test/?utm_source=1234', a['href'].to_s
    end

    premailer = Premailer.new("<a href='/test/?123&456'>Link</a>", :link_query_string => qs, :with_html_string => true)
    premailer.to_inline_css
    
    assert_equal '/test/?123&456&amp;utm_source=1234', premailer.processed_doc.at('a')['href']
  end


  def test_preserving_links
    html = "<a href='http://example.com/index.php?pram1=one&pram2=two'>Link</a>"
    premailer = Premailer.new(html.to_s, :link_query_string => '', :with_html_string => true)
    premailer.to_inline_css
    
    assert_equal 'http://example.com/index.php?pram1=one&pram2=two', premailer.processed_doc.at('a')['href']

    html = "<a href='http://example.com/index.php?pram1=one&pram2=two'>Link</a>"
    premailer = Premailer.new(html.to_s, :link_query_string => 'qs', :with_html_string => true)
    premailer.to_inline_css
    
    assert_equal 'http://example.com/index.php?pram1=one&pram2=two&amp;qs', premailer.processed_doc.at('a')['href']

  end

  def test_resolving_urls_from_string
    ['test.html', '/test.html', './test.html', 
     'test/../test.html', 'test/../test/../test.html'].each do |q|
      assert_equal 'http://example.com/test.html', Premailer.resolve_link(q, 'http://example.com/'), q
    end

    assert_equal 'https://example.net:80/~basedir/test.html?var=1#anchor', Premailer.resolve_link('test/../test/../test.html?var=1#anchor', 'https://example.net:80/~basedir/')
  end

  def test_resolving_urls_from_uri
    base_uri = URI.parse('http://example.com/')
    ['test.html', '/test.html', './test.html', 
     'test/../test.html', 'test/../test/../test.html'].each do |q|
      assert_equal 'http://example.com/test.html', Premailer.resolve_link(q, base_uri), q
    end

    base_uri = URI.parse('https://example.net:80/~basedir/')
    assert_equal 'https://example.net:80/~basedir/test.html?var=1#anchor', Premailer.resolve_link('test/../test/../test.html?var=1#anchor', base_uri)
    
    # base URI with a query string
    base_uri = URI.parse('http://example.com/dir/index.cfm?newsletterID=16')
    assert_equal 'http://example.com/dir/index.cfm?link=15', Premailer.resolve_link('?link=15', base_uri)
    
    # URI preceded by a space
    base_uri = URI.parse('http://example.com/')
    assert_equal 'http://example.com/path', Premailer.resolve_link(' path', base_uri)
  end

  def test_resolving_urls_in_doc
    # force Nokogiri since this consistenly segfaults with Hpricot
    base_file = File.dirname(__FILE__) + '/files/base.html'
    base_url = 'https://my.example.com:8080/test-path.html'
    premailer = Premailer.new(base_file, :base_url => base_url, :adapter => :nokogiri)
    premailer.to_inline_css
    pdoc = premailer.processed_doc
    doc = premailer.doc

    # unchanged links
    ['#l02', '#l03', '#l05', '#l06', '#l07', '#l08', 
     '#l09', '#l10', '#l11', '#l12', '#l13'].each do |link_id|
      assert_equal doc.at(link_id).attributes['href'], pdoc.at(link_id).attributes['href'], link_id
    end
    
    assert_equal 'https://my.example.com:8080/', pdoc.at('#l01').attributes['href'].to_s
    assert_equal 'https://my.example.com:8080/images/', pdoc.at('#l04').attributes['href'].to_s
  end
end
