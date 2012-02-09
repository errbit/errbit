require File.expand_path('test_helper', File.dirname(__FILE__))

class Brands; end
class Category; end

class Product
  def self.human_name; 'Product'; end
end

class ProductsController < InheritedResources::Base
  belongs_to :brand, :category, :polymorphic => true, :optional => true
end

class OptionalTest < ActionController::TestCase
  tests ProductsController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_all_products_as_instance_variable_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:scoped).returns([mock_product])
    get :index, :category_id => '37'
    assert_equal mock_category, assigns(:category)
    assert_equal [mock_product], assigns(:products)
  end

  def test_expose_all_products_as_instance_variable_without_category
    Product.expects(:scoped).returns([mock_product])
    get :index
    assert_equal nil, assigns(:category)
    assert_equal [mock_product], assigns(:products)
  end

  def test_expose_the_requested_product_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:find).with('42').returns(mock_product)
    get :show, :id => '42', :category_id => '37'
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_the_requested_product_without_category
    Product.expects(:find).with('42').returns(mock_product)
    get :show, :id => '42'
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_a_new_product_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:build).returns(mock_product)
    get :new, :category_id => '37'
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_a_new_product_without_category
    Product.expects(:new).returns(mock_product)
    get :new
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_the_requested_product_for_edition_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:find).with('42').returns(mock_product)
    get :edit, :id => '42', :category_id => '37'
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_the_requested_product_for_edition_without_category
    Product.expects(:find).with('42').returns(mock_product)
    get :edit, :id => '42'
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_a_newly_create_product_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:build).with({'these' => 'params'}).returns(mock_product(:save => true))
    post :create, :category_id => '37', :product => {:these => 'params'}
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_expose_a_newly_create_product_without_category
    Product.expects(:new).with({'these' => 'params'}).returns(mock_product(:save => true))
    post :create, :product => {:these => 'params'}
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_update_the_requested_object_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:find).with('42').returns(mock_product)
    mock_product.expects(:update_attributes).with({'these' => 'params'}).returns(true)

    put :update, :id => '42', :category_id => '37', :product => {:these => 'params'}
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_update_the_requested_object_without_category
    Product.expects(:find).with('42').returns(mock_product)
    mock_product.expects(:update_attributes).with({'these' => 'params'}).returns(true)

    put :update, :id => '42', :product => {:these => 'params'}
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_the_requested_product_is_destroyed_with_category
    Category.expects(:find).with('37').returns(mock_category)
    mock_category.expects(:products).returns(Product)
    Product.expects(:find).with('42').returns(mock_product)
    mock_product.expects(:destroy).returns(true)
    @controller.expects(:collection_url).returns('/')

    delete :destroy, :id => '42', :category_id => '37'
    assert_equal mock_category, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_the_requested_product_is_destroyed_without_category
    Product.expects(:find).with('42').returns(mock_product)
    mock_product.expects(:destroy).returns(true)
    @controller.expects(:collection_url).returns('/')

    delete :destroy, :id => '42'
    assert_equal nil, assigns(:category)
    assert_equal mock_product, assigns(:product)
  end

  def test_polymorphic_helpers
    Product.expects(:scoped).returns([mock_product])
    get :index

    assert !@controller.send(:parent?)
    assert_equal nil, assigns(:parent_type)
    assert_equal nil, @controller.send(:parent_type)
    assert_equal nil, @controller.send(:parent_class)
    assert_equal nil, assigns(:category)
    assert_equal nil, @controller.send(:parent)
  end

  protected
    def mock_category(stubs={})
      @mock_category ||= mock(stubs)
    end

    def mock_product(stubs={})
      @mock_product ||= mock(stubs)
    end
end
