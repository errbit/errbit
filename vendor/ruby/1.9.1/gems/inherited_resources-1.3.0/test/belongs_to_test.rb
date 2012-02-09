require File.expand_path('test_helper', File.dirname(__FILE__))

class Post
  extend ActiveModel::Naming
end

class Comment
  extend ActiveModel::Naming
end

class CommentsController < InheritedResources::Base
  belongs_to :post
end

class BelongsToTest < ActionController::TestCase
  tests CommentsController

  def setup
    Post.expects(:find).with('37').returns(mock_post)
    mock_post.expects(:comments).returns(Comment)

    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_all_comments_as_instance_variable_on_index
    Comment.expects(:scoped).returns([mock_comment])
    get :index, :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal [mock_comment], assigns(:comments)
  end

  def test_expose_the_requested_comment_on_show
    Comment.expects(:find).with('42').returns(mock_comment)
    get :show, :id => '42', :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def test_expose_a_new_comment_on_new
    Comment.expects(:build).returns(mock_comment)
    get :new, :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def test_expose_the_requested_comment_on_edit
    Comment.expects(:find).with('42').returns(mock_comment)
    get :edit, :id => '42', :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def test_redirect_to_the_post_on_update_if_show_and_index_undefined
    @controller.class.send(:actions, :all, :except => [:show, :index])
    @controller.expects(:parent_url).returns('http://test.host/')
    Comment.expects(:build).with({'these' => 'params'}).returns(mock_comment(:save => true))
    post :create, :post_id => '37', :comment => {:these => 'params'}
    assert_redirected_to 'http://test.host/'
  end

  def test_expose_a_newly_create_comment_on_create
    Comment.expects(:build).with({'these' => 'params'}).returns(mock_comment(:save => true))
    post :create, :post_id => '37', :comment => {:these => 'params'}
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def test_redirect_to_the_post_on_update_if_show_and_index_undefined
    @controller.class.send(:actions, :all, :except => [:show, :index])
    Comment.stubs(:find).returns(mock_comment(:update_attributes => true))
    @controller.expects(:parent_url).returns('http://test.host/')
    put :update, :id => '42', :post_id => '37', :comment => {:these => 'params'}
    assert_redirected_to 'http://test.host/'
  end

  def test_update_the_requested_object_on_update
    Comment.expects(:find).with('42').returns(mock_comment)
    mock_comment.expects(:update_attributes).with({'these' => 'params'}).returns(true)
    put :update, :id => '42', :post_id => '37', :comment => {:these => 'params'}
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def test_redirect_to_the_post_on_destroy_if_show_and_index_undefined
    @controller.class.send(:actions, :all, :except => [:show, :index])
    Comment.expects(:find).with('42').returns(mock_comment)
    mock_comment.expects(:destroy)
    @controller.expects(:parent_url).returns('http://test.host/')
    delete :destroy, :id => '42', :post_id => '37'
    assert_redirected_to 'http://test.host/'
  end

  def test_the_requested_comment_is_destroyed_on_destroy
    Comment.expects(:find).with('42').returns(mock_comment)
    mock_comment.expects(:destroy)
    delete :destroy, :id => '42', :post_id => '37'
    assert_equal mock_post, assigns(:post)
    assert_equal mock_comment, assigns(:comment)
  end

  def helper_methods
    @controller.class._helpers.instance_methods.map {|m| m.to_s }
  end

  def test_helpers
    mock_post.stubs(:class).returns(Post)

    Comment.expects(:scoped).returns([mock_comment])
    get :index, :post_id => '37'

    assert helper_methods.include?('parent?')
    assert @controller.send(:parent?)
    assert_equal mock_post, assigns(:post)
    assert helper_methods.include?('parent')
    assert_equal mock_post, @controller.send(:parent)
  end

  protected

    def mock_post(stubs={})
      @mock_post ||= mock(stubs)
    end

    def mock_comment(stubs={})
      @mock_comment ||= mock(stubs)
    end

end

