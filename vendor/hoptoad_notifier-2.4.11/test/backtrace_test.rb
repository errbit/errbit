require File.dirname(__FILE__) + '/helper'

class BacktraceTest < Test::Unit::TestCase

  should "parse a backtrace into lines" do
    array = [
      "app/models/user.rb:13:in `magic'",
      "app/controllers/users_controller.rb:8:in `index'"
    ]

    backtrace = HoptoadNotifier::Backtrace.parse(array)

    line = backtrace.lines.first
    assert_equal '13', line.number
    assert_equal 'app/models/user.rb', line.file
    assert_equal 'magic', line.method

    line = backtrace.lines.last
    assert_equal '8', line.number
    assert_equal 'app/controllers/users_controller.rb', line.file
    assert_equal 'index', line.method
  end
  
  should "parse a windows backtrace into lines" do
    array = [
      "C:/Program Files/Server/app/models/user.rb:13:in `magic'",
      "C:/Program Files/Server/app/controllers/users_controller.rb:8:in `index'"
    ]

    backtrace = HoptoadNotifier::Backtrace.parse(array)

    line = backtrace.lines.first
    assert_equal '13', line.number
    assert_equal 'C:/Program Files/Server/app/models/user.rb', line.file
    assert_equal 'magic', line.method

    line = backtrace.lines.last
    assert_equal '8', line.number
    assert_equal 'C:/Program Files/Server/app/controllers/users_controller.rb', line.file
    assert_equal 'index', line.method
  end

  should "be equal with equal lines" do
    one = build_backtrace_array
    two = one.dup
    assert_equal one, two

    assert_equal HoptoadNotifier::Backtrace.parse(one), HoptoadNotifier::Backtrace.parse(two)
  end

  should "parse massive one-line exceptions into multiple lines" do
    original_backtrace = HoptoadNotifier::Backtrace.
      parse(["one:1:in `one'\n   two:2:in `two'\n      three:3:in `three`"])
    expected_backtrace = HoptoadNotifier::Backtrace.
      parse(["one:1:in `one'", "two:2:in `two'", "three:3:in `three`"])

    assert_equal expected_backtrace, original_backtrace
  end

  context "with a project root" do
    setup do
      @project_root = '/some/path'
      HoptoadNotifier.configure {|config| config.project_root = @project_root }
    end

    teardown do
      reset_config
    end

    should "filter out the project root" do
      backtrace_with_root = HoptoadNotifier::Backtrace.parse(
        ["#{@project_root}/app/models/user.rb:7:in `latest'",
         "#{@project_root}/app/controllers/users_controller.rb:13:in `index'",
         "/lib/something.rb:41:in `open'"],
        :filters => default_filters)
      backtrace_without_root = HoptoadNotifier::Backtrace.parse(
        ["[PROJECT_ROOT]/app/models/user.rb:7:in `latest'",
         "[PROJECT_ROOT]/app/controllers/users_controller.rb:13:in `index'",
         "/lib/something.rb:41:in `open'"])

      assert_equal backtrace_without_root, backtrace_with_root
    end
  end

  context "with a blank project root" do
    setup do
      HoptoadNotifier.configure {|config| config.project_root = '' }
    end

    teardown do
      reset_config
    end

    should "not filter line numbers with respect to any project root" do
      backtrace = ["/app/models/user.rb:7:in `latest'",
                   "/app/controllers/users_controller.rb:13:in `index'",
                   "/lib/something.rb:41:in `open'"]

      backtrace_with_root =
        HoptoadNotifier::Backtrace.parse(backtrace, :filters => default_filters)

      backtrace_without_root =
        HoptoadNotifier::Backtrace.parse(backtrace)

      assert_equal backtrace_without_root, backtrace_with_root
    end
  end

  should "remove notifier trace" do
    inside_notifier  = ['lib/hoptoad_notifier.rb:13:in `voodoo`']
    outside_notifier = ['users_controller:8:in `index`']

    without_inside = HoptoadNotifier::Backtrace.parse(outside_notifier)
    with_inside    = HoptoadNotifier::Backtrace.parse(inside_notifier + outside_notifier,
                                                      :filters => default_filters)

    assert_equal without_inside, with_inside
  end

  should "run filters on the backtrace" do
    filters = [lambda { |line| line.sub('foo', 'bar') }]
    input = HoptoadNotifier::Backtrace.parse(["foo:13:in `one'", "baz:14:in `two'"],
                                             :filters => filters)
    expected = HoptoadNotifier::Backtrace.parse(["bar:13:in `one'", "baz:14:in `two'"])
    assert_equal expected, input
  end

  def build_backtrace_array
    ["app/models/user.rb:13:in `magic'",
      "app/controllers/users_controller.rb:8:in `index'"]
  end

  def default_filters
    HoptoadNotifier::Configuration::DEFAULT_BACKTRACE_FILTERS
  end

end
