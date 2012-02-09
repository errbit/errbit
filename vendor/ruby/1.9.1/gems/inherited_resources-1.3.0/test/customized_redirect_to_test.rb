require File.expand_path('test_helper', File.dirname(__FILE__))

class Post;
  def self.human_name; 'Post'; end
end

class PostsController < InheritedResources::Base
    actions :all, :except => [:show]
end

class RedirectToIndexWithoutShowTest < ActionController::TestCase
  tests PostsController

  def test_redirect_index_url_after_create
    Post.stubs(:new).returns(mock_machine(:save => true))
    assert !PostsController.respond_to?(:show)
    post :create
    assert_redirected_to 'http://test.host/posts'
  end

   def test_redirect_to_index_url_after_update
     Post.stubs(:find).returns(mock_machine(:update_attributes => true))
     assert !PostsController.respond_to?(:show)
     put :update
     assert_redirected_to 'http://test.host/posts'
   end

  protected
    def mock_machine(stubs={})
      @mock_machine ||= mock(stubs)
    end
end
