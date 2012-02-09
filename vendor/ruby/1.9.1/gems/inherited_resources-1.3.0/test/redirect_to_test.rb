require File.expand_path('test_helper', File.dirname(__FILE__))

class Machine;
  def self.human_name; 'Machine'; end
end

class MachinesController < InheritedResources::Base
  def create
    create!{ complex_url(:create, true, true) }
  end

  def update
    update!{ complex_url(:update, false, false) }
  end

  def destroy
    destroy!{ complex_url(:destroy, true, false) }
  end

  protected
    def complex_url(name, arg2, arg3)
      'http://test.host/' + name.to_s
    end
end

class RedirectToWithBlockTest < ActionController::TestCase
  tests MachinesController

  def test_redirect_to_the_given_url_on_create
    Machine.stubs(:new).returns(mock_machine(:save => true))
    post :create
    assert_redirected_to 'http://test.host/create'
  end

  def test_redirect_to_the_given_url_on_update
    Machine.stubs(:find).returns(mock_machine(:update_attributes => true))
    put :update
    assert_redirected_to 'http://test.host/update'
  end

  def test_redirect_to_the_given_url_on_destroy
    Machine.stubs(:find).returns(mock_machine(:destroy => true))
    delete :destroy
    assert_redirected_to 'http://test.host/destroy'
  end

  protected
    def mock_machine(stubs={})
      @mock_machine ||= mock(stubs)
    end
end
