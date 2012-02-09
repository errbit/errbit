require File.expand_path('test_helper', File.dirname(__FILE__))

class Dresser
end

class Shelf
end

class Plate
end

class PlatesController < InheritedResources::Base
  belongs_to :dresser, :shelf, :shallow => true
end

class NestedBelongsToWithShallowTest < ActionController::TestCase
  tests PlatesController

  def setup
    mock_shelf.expects(:dresser).returns(mock_dresser)
    mock_dresser.expects(:to_param).returns('13')

    Dresser.expects(:find).with('13').returns(mock_dresser)
    mock_dresser.expects(:shelves).returns(Shelf)
    mock_shelf.expects(:plates).returns(Plate)

    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_assigns_dresser_and_shelf_and_plate_on_index
    Shelf.expects(:find).with('37').twice.returns(mock_shelf)
    Plate.expects(:scoped).returns([mock_plate])
    get :index, :shelf_id => '37'

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal [mock_plate], assigns(:plates)
  end

  def test_assigns_dresser_and_shelf_and_plate_on_show
    should_find_parents
    get :show, :id => '42'

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end

  def test_assigns_dresser_and_shelf_and_plate_on_new
    Plate.expects(:build).returns(mock_plate)
    Shelf.expects(:find).with('37').twice.returns(mock_shelf)
    get :new, :shelf_id => '37'

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end

  def test_assigns_dresser_and_shelf_and_plate_on_edit
    should_find_parents
    get :edit, :id => '42'

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end


  def test_assigns_dresser_and_shelf_and_plate_on_create
    Shelf.expects(:find).with('37').twice.returns(mock_shelf)

    Plate.expects(:build).with({'these' => 'params'}).returns(mock_plate)
    mock_plate.expects(:save).returns(true)
    post :create, :shelf_id => '37', :plate => {:these => 'params'}

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end

  def test_assigns_dresser_and_shelf_and_plate_on_update
    should_find_parents
    mock_plate.expects(:update_attributes).returns(true)
    put :update, :id => '42', :plate => {:these => 'params'}

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end

  def test_assigns_dresser_and_shelf_and_plate_on_destroy
    should_find_parents
    mock_plate.expects(:destroy)
    delete :destroy, :id => '42'

    assert_equal mock_dresser, assigns(:dresser)
    assert_equal mock_shelf, assigns(:shelf)
    assert_equal mock_plate, assigns(:plate)
  end


  protected
    def should_find_parents
      Plate.expects(:find).with('42').returns(mock_plate)
      mock_plate.expects(:shelf).returns(mock_shelf)
      mock_shelf.expects(:to_param).returns('37')
      Plate.expects(:find).with('42').returns(mock_plate)
      Shelf.expects(:find).with('37').returns(mock_shelf)
    end

    def mock_dresser(stubs={})
      @mock_dresser ||= mock(stubs)
    end

    def mock_shelf(stubs={})
      @mock_shelf ||= mock(stubs)
    end

    def mock_plate(stubs={})
      @mock_plate ||= mock(stubs)
    end
end
