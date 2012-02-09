require File.expand_path('test_helper', File.dirname(__FILE__))

class Book; end
class Folder; end

class BooksController < InheritedResources::Base
  custom_actions :collection => :search, :resource => [:delete]
  actions :index, :show
end

class ReadersController < InheritedResources::Base
  actions :all, :except => [ :edit, :update ]
end

class FoldersController < InheritedResources::Base
end

class Dean
  def self.human_name; 'Dean'; end
end

class DeansController < InheritedResources::Base
  belongs_to :school
end

class ActionsClassMethodTest < ActionController::TestCase
  tests BooksController

  def test_cannot_render_actions
    assert_raise ActionController::UnknownAction do
      get :new
    end
  end

  def test_actions_are_undefined
    action_methods = BooksController.send(:action_methods).map(&:to_sym)
    assert_equal 4, action_methods.size

    [:index, :show, :delete, :search].each do |action|
      assert action_methods.include?(action)
    end

    instance_methods = BooksController.send(:instance_methods).map(&:to_sym)

    [:new, :edit, :create, :update, :destroy].each do |action|
      assert !instance_methods.include?(action)
    end
  end

  def test_actions_are_undefined_when_except_option_is_given
    action_methods = ReadersController.send(:action_methods)
    assert_equal 5, action_methods.size

    ['index', 'new', 'show', 'create', 'destroy'].each do |action|
      assert action_methods.include? action
    end
  end

end

class DefaultsClassMethodTest < ActiveSupport::TestCase
  def test_resource_class_is_set_to_nil_when_resource_model_cannot_be_found
    assert_nil ReadersController.send(:resource_class)
  end

  def test_defaults_are_set
    assert_equal Folder, FoldersController.send(:resource_class)
    assert_equal :folder, FoldersController.send(:resources_configuration)[:self][:instance_name]
    assert_equal :folders, FoldersController.send(:resources_configuration)[:self][:collection_name]
  end

  def test_defaults_can_be_overwriten
    BooksController.send(:defaults, :resource_class => String, :instance_name => 'string', :collection_name => 'strings')

    assert_equal String, BooksController.send(:resource_class)
    assert_equal :string, BooksController.send(:resources_configuration)[:self][:instance_name]
    assert_equal :strings, BooksController.send(:resources_configuration)[:self][:collection_name]

    BooksController.send(:defaults, :class_name => 'Fixnum', :instance_name => :fixnum, :collection_name => :fixnums)

    assert_equal Fixnum, BooksController.send(:resource_class)
    assert_equal :fixnum, BooksController.send(:resources_configuration)[:self][:instance_name]
    assert_equal :fixnums, BooksController.send(:resources_configuration)[:self][:collection_name]
  end

  def test_defaults_raises_invalid_key
    assert_raise ArgumentError do
      BooksController.send(:defaults, :boom => String)
    end
  end

  def test_url_helpers_are_recreated_when_defaults_change
    BooksController.expects(:create_resources_url_helpers!).returns(true).once
    BooksController.send(:defaults, :instance_name => 'string', :collection_name => 'strings')
  end
end

class BelongsToErrorsTest < ActiveSupport::TestCase
  def test_belongs_to_raise_errors_with_invalid_arguments
    assert_raise ArgumentError do
      DeansController.send(:belongs_to)
    end

    assert_raise ArgumentError do
      DeansController.send(:belongs_to, :nice, :invalid_key => '')
    end
  end

  def test_belongs_to_raises_an_error_when_multiple_associations_are_given_with_options
    assert_raise ArgumentError do
      DeansController.send(:belongs_to, :arguments, :with_options, :parent_class => Professor)
    end
  end

  def test_url_helpers_are_recreated_just_once_when_belongs_to_is_called_with_block
    DeansController.expects(:create_resources_url_helpers!).returns(true).once
    DeansController.send(:belongs_to, :school) do
      belongs_to :association
    end
  ensure
    DeansController.send(:parents_symbols=, [:school])
  end

  def test_url_helpers_are_recreated_just_once_when_belongs_to_is_called_with_multiple_blocks
    DeansController.expects(:create_resources_url_helpers!).returns(true).once
    DeansController.send(:belongs_to, :school) do
      belongs_to :association do
        belongs_to :nested
      end
    end
  ensure
    DeansController.send(:parents_symbols=, [:school])
  end
end
