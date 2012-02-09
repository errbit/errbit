require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Test cases for the CssParser's loading functions.
class CssParserLoadingTests < Test::Unit::TestCase
  include CssParser
  include WEBrick

  def setup
    # from http://nullref.se/blog/2006/5/17/testing-with-webrick
    @cp = Parser.new

    @uri_base = 'http://localhost:12000'

    @www_root = File.dirname(__FILE__) + '/fixtures/'

    @server_thread = Thread.new do
      s = WEBrick::HTTPServer.new(:Port => 12000, :DocumentRoot => @www_root, :Logger => Log.new(nil, BasicLog::FATAL), :AccessLog => [])
      @port = s.config[:Port]
      begin
        s.start
      ensure
        s.shutdown
      end
    end

    sleep 1 # ensure the server has time to load
  end
 
  def teardown
    @server_thread.kill
    @server_thread.join(5)
    @server_thread = nil
  end
 
  def test_loading_a_local_file
    file_name = File.dirname(__FILE__) + '/fixtures/simple.css'
    @cp.load_file!(file_name)
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end

  def test_loading_a_local_file_with_scheme
    file_name = 'file://' + File.expand_path(File.dirname(__FILE__)) + '/fixtures/simple.css'
    @cp.load_uri!(file_name)
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end

  def test_loading_a_remote_file
    @cp.load_uri!("#{@uri_base}/simple.css")
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end

  # http://github.com/alexdunae/css_parser/issues#issue/4
  def test_loading_a_remote_file_over_ssl
    # TODO: test SSL locally
    @cp.load_uri!("https://dialect.ca/inc/screen.css")
    assert_match /margin\: 0\;/, @cp.find_by_selector('body').join(' ')
  end


  def test_following_at_import_rules_local
    base_dir = File.dirname(__FILE__) + '/fixtures'
    @cp.load_file!('import1.css', base_dir)

    # from '/import1.css'
    assert_equal 'color: lime;', @cp.find_by_selector('div').join(' ')

    # from '/subdir/import2.css'
    assert_equal 'text-decoration: none;', @cp.find_by_selector('a').join(' ')
    
    # from '/subdir/../simple.css'
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end

  def test_following_at_import_rules_remote
    @cp.load_uri!("#{@uri_base}/import1.css")

    # from '/import1.css'
    assert_equal 'color: lime;', @cp.find_by_selector('div').join(' ')

    # from '/subdir/import2.css'
    assert_equal 'text-decoration: none;', @cp.find_by_selector('a').join(' ')
    
    # from '/subdir/../simple.css'
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end
  
  def test_following_badly_escaped_import_rules
    css_block = '@import "http://example.com/css?family=Droid+Sans:regular,bold|Droid+Serif:regular,italic,bold,bolditalic&subset=latin";'

    assert_nothing_raised do
      @cp.add_block!(css_block, :base_uri => "#{@uri_base}/subdir/")
    end
  end

  def test_following_at_import_rules_from_add_block
    css_block = '@import "../simple.css";'
 
    @cp.add_block!(css_block, :base_uri => "#{@uri_base}/subdir/")
    
    # from 'simple.css'
    assert_equal 'margin: 0px;', @cp.find_by_selector('p').join(' ')
  end

  def test_importing_with_media_types
    @cp.load_uri!("#{@uri_base}/import-with-media-types.css")
    
    # from simple.css with :screen media type
    assert_equal 'margin: 0px;', @cp.find_by_selector('p', :screen).join(' ')
    assert_equal '', @cp.find_by_selector('p', :tty).join(' ')
  end

  def test_local_circular_reference_exception
    assert_raise CircularReferenceError do
      @cp.load_file!(File.dirname(__FILE__) + '/fixtures/import-circular-reference.css')
    end
  end

  def test_remote_circular_reference_exception
    assert_raise CircularReferenceError do
      @cp.load_uri!("#{@uri_base}/import-circular-reference.css")
    end
  end

  def test_suppressing_circular_reference_exceptions
    cp_without_exceptions = Parser.new(:io_exceptions => false)

    assert_nothing_raised CircularReferenceError do
      cp_without_exceptions.load_uri!("#{@uri_base}/import-circular-reference.css")
    end
  end

  def test_toggling_not_found_exceptions
    cp_with_exceptions = Parser.new(:io_exceptions => true)

    assert_raise RemoteFileError do
      cp_with_exceptions.load_uri!("#{@uri_base}/no-exist.xyz")
    end

    cp_without_exceptions = Parser.new(:io_exceptions => false)

    assert_nothing_raised RemoteFileError do
      cp_without_exceptions.load_uri!("#{@uri_base}/no-exist.xyz")
    end
  end

end
