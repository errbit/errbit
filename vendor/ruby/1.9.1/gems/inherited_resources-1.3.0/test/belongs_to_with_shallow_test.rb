require File.expand_path('test_helper', File.dirname(__FILE__))

class Post
  extend ActiveModel::Naming
end

class Tag
  extend ActiveModel::Naming
end

class TagsController < InheritedResources::Base
  belongs_to :post, :shallow => true, :finder => :find_by_slug
end

class BelongsToWithShallowTest < ActionController::TestCase
  tests TagsController

  def setup
    Post.expects(:find_by_slug).with('thirty_seven').returns(mock_post)
    mock_post.expects(:tags).returns(Tag)

    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_all_tags_as_instance_variable_on_index
    Tag.expects(:scoped).returns([mock_tag])
    get :index, :post_id => 'thirty_seven'
    assert_equal mock_post, assigns(:post)
    assert_equal [mock_tag], assigns(:tags)
  end

  def test_expose_a_new_tag_on_new
    Tag.expects(:build).returns(mock_tag)
    get :new, :post_id => 'thirty_seven'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  def test_expose_a_newly_create_tag_on_create
    Tag.expects(:build).with({'these' => 'params'}).returns(mock_tag(:save => true))
    post :create, :post_id => 'thirty_seven', :tag => {:these => 'params'}
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  def test_expose_the_requested_tag_on_show
    should_find_parents
    get :show, :id => '42'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  def test_expose_the_requested_tag_on_edit
    should_find_parents
    get :edit, :id => '42'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  def test_update_the_requested_object_on_update
    should_find_parents
    mock_tag.expects(:update_attributes).with({'these' => 'params'}).returns(true)
    put :update, :id => '42', :tag => {:these => 'params'}
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  def test_the_requested_tag_is_destroyed_on_destroy
    should_find_parents
    mock_tag.expects(:destroy)
    delete :destroy, :id => '42', :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_tag, assigns(:tag)
  end

  protected
    def should_find_parents
      mock_tag.expects(:post).returns(mock_post)
      mock_post.expects(:to_param).returns('thirty_seven')
      Tag.expects(:find).with('42').twice.returns(mock_tag)
    end

    def mock_post(stubs={})
      @mock_post ||= mock(stubs)
    end

    def mock_tag(stubs={})
      @mock_tag ||= mock(stubs)
    end

end

