require File.expand_path('test_helper', File.dirname(__FILE__))

class Universe
  extend ActiveModel::Naming
end
class UniversesController < InheritedResources::Base
  defaults :singleton => true, :route_instance_name => 'universum'
end

class House
  extend ActiveModel::Naming
end
class HousesController < InheritedResources::Base
end

class News
  extend ActiveModel::Naming
end
class NewsController < InheritedResources::Base
end

class Backpack
  extend ActiveModel::Naming
end
module Admin; end
class Admin::BackpacksController < InheritedResources::Base
  defaults :route_collection_name => 'tour_backpacks'
end

class Table
  extend ActiveModel::Naming
end
class TablesController < InheritedResources::Base
  belongs_to :house
end

class RoomsController < InheritedResources::Base
  belongs_to :house, :route_name => 'big_house'
end

class ChairsController < InheritedResources::Base
  belongs_to :house do
    belongs_to :table
  end
end

class OwnersController < InheritedResources::Base
  singleton_belongs_to :house
end

class Bed
  extend ActiveModel::Naming
end
class BedsController < InheritedResources::Base
  optional_belongs_to :house, :building
end

class Sheep
  extend ActiveModel::Naming
end
class SheepController < InheritedResources::Base
  belongs_to :news, :table, :polymorphic => true
end

class Desk
  extend ActiveModel::Naming
end
module Admin
  class DesksController < InheritedResources::Base
    optional_belongs_to :house
  end
end

class Dish
  extend ActiveModel::Naming
end
class DishesController < InheritedResources::Base
  belongs_to :house do
    polymorphic_belongs_to :table, :kitchen
  end
end

class Center
  extend ActiveModel::Naming
end
class CentersController < InheritedResources::Base
  acts_as_singleton!

  belongs_to :house do
    belongs_to :table, :kitchen, :polymorphic => true
  end
end

class Mirror
  extend ActiveModel::Naming
end
class MirrorsController < InheritedResources::Base
  belongs_to :house, :shallow => true
end
class Admin::MirrorsController < InheritedResources::Base
  belongs_to :house, :shallow => true
end


class Display
  extend ActiveModel::Naming
end

class Window
  extend ActiveModel::Naming
end

class Button
  extend ActiveModel::Naming
end

class ButtonsController < InheritedResources::Base
  belongs_to :display, :window, :shallow => true
  custom_actions :resource => :delete, :collection => :search
end

class ImageButtonsController < ButtonsController
end


# Create a TestHelper module with some helpers
class UrlHelpersTest < ActiveSupport::TestCase
  def mock_polymorphic(controller, route)
    controller.expects(:url_for).with(:no=>"no")
    controller._routes.url_helpers.expects("hash_for_#{route}").returns({:no=>"no"})    
  end

  def test_url_helpers_on_simple_inherited_resource
    controller = HousesController.new
    controller.instance_variable_set('@house', :house)

    [:url, :path].each do |path_or_url|
      controller.expects("houses_#{path_or_url}").with({}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("house_#{path_or_url}").with(:house, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_house_#{path_or_url}").with({}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_resource_#{path_or_url}")

      # With arg
      controller.expects("house_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("house_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      # With options
      controller.expects("house_#{path_or_url}").with(:arg, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_simple_inherited_resource_using_uncountable
    controller = NewsController.new
    controller.instance_variable_set('@news', :news)

    [:url, :path].each do |path_or_url|
      controller.expects("news_index_#{path_or_url}").with({}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("news_#{path_or_url}").with(:news, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_news_#{path_or_url}").with({}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_news_#{path_or_url}").with(:news, {}).once
      controller.send("edit_resource_#{path_or_url}")

      # With arg
      controller.expects("news_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("news_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      # With options
      controller.expects("news_#{path_or_url}").with(:arg, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_simple_inherited_namespaced_resource
    controller = Admin::BackpacksController.new
    controller.instance_variable_set('@backpack', :backpack)

    assert_equal 'admin', controller.class.resources_configuration[:self][:route_prefix]

    [:url, :path].each do |path_or_url|
      controller.expects("admin_tour_backpacks_#{path_or_url}").with({}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("admin_backpack_#{path_or_url}").with(:backpack, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_admin_backpack_#{path_or_url}").with({}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_admin_backpack_#{path_or_url}").with(:backpack, {}).once
      controller.send("edit_resource_#{path_or_url}")

      # With arg
      controller.expects("admin_backpack_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("admin_backpack_#{path_or_url}").with(:arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      # With options
      controller.expects("admin_backpack_#{path_or_url}").with(:arg, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_simple_inherited_singleton_resource
    controller = UniversesController.new
    controller.instance_variable_set('@universe', :universe)

    [:url, :path].each do |path_or_url|
      controller.expects("root_#{path_or_url}").with({}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("universum_#{path_or_url}").with({}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_universum_#{path_or_url}").with({}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_universum_#{path_or_url}").with({}).once
      controller.send("edit_resource_#{path_or_url}")

      # With options
      # Also tests that argument sent are not used
      controller.expects("universum_#{path_or_url}").with(:page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_belongs_to
    controller = TablesController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@table', :table)

    [:url, :path].each do |path_or_url|
      controller.expects("house_tables_#{path_or_url}").with(:house, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("house_table_#{path_or_url}").with(:house, :table, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_house_table_#{path_or_url}").with(:house, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_house_table_#{path_or_url}").with(:house, :table, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("house_#{path_or_url}").with(:house, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_parent_#{path_or_url}")

      # With arg
      controller.expects("house_table_#{path_or_url}").with(:house, :arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("edit_house_table_#{path_or_url}").with(:house, :arg, {}).once
      controller.send("edit_resource_#{path_or_url}", :arg)

      controller.expects("house_#{path_or_url}").with(:arg, {}).once
      controller.send("parent_#{path_or_url}", :arg)

      # With options
      controller.expects("house_table_#{path_or_url}").with(:house, :arg, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_not_default_belongs_to
    controller = RoomsController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@room', :room)

    [:url, :path].each do |path_or_url|
      controller.expects("big_house_rooms_#{path_or_url}").with(:house, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("big_house_room_#{path_or_url}").with(:house, :room, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_big_house_room_#{path_or_url}").with(:house, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_big_house_room_#{path_or_url}").with(:house, :room, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("big_house_#{path_or_url}").with(:house, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_big_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_parent_#{path_or_url}")

      # With args
      controller.expects("big_house_room_#{path_or_url}").with(:house, :arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("edit_big_house_room_#{path_or_url}").with(:house, :arg, {}).once
      controller.send("edit_resource_#{path_or_url}", :arg)

      controller.expects("big_house_#{path_or_url}").with(:arg, {}).once
      controller.send("parent_#{path_or_url}", :arg)

      # With options
      controller.expects("big_house_room_#{path_or_url}").with(:house, :arg, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_nested_belongs_to
    controller = ChairsController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@table', :table)
    controller.instance_variable_set('@chair', :chair)

    [:url, :path].each do |path_or_url|
      controller.expects("house_table_chairs_#{path_or_url}").with(:house, :table, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("house_table_chair_#{path_or_url}").with(:house, :table, :chair, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_house_table_chair_#{path_or_url}").with(:house, :table, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_house_table_chair_#{path_or_url}").with(:house, :table, :chair, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("house_table_#{path_or_url}").with(:house, :table, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_house_table_#{path_or_url}").with(:house, :table, {}).once
      controller.send("edit_parent_#{path_or_url}")

      # With args
      controller.expects("edit_house_table_chair_#{path_or_url}").with(:house, :table, :arg, {}).once
      controller.send("edit_resource_#{path_or_url}", :arg)

      controller.expects("house_table_chair_#{path_or_url}").with(:house, :table, :arg, {}).once
      controller.send("resource_#{path_or_url}", :arg)

      controller.expects("house_table_#{path_or_url}").with(:house, :arg, {}).once
      controller.send("parent_#{path_or_url}", :arg)

      # With options
      controller.expects("edit_house_table_chair_#{path_or_url}").with(:house, :table, :arg, :page => 1).once
      controller.send("edit_resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_singletons_with_belongs_to
    controller = OwnersController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@owner', :owner)

    [:url, :path].each do |path_or_url|
      controller.expects("house_#{path_or_url}").with(:house, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("house_owner_#{path_or_url}").with(:house, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_house_owner_#{path_or_url}").with(:house, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_house_owner_#{path_or_url}").with(:house, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("house_#{path_or_url}").with(:house, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_parent_#{path_or_url}")

      # With options
      # Also tests that argument sent are not used
      controller.expects("house_owner_#{path_or_url}").with(:house, :page => 1).once
      controller.send("resource_#{path_or_url}", :arg, :page => 1)
    end
  end

  def test_url_helpers_on_polymorphic_belongs_to
    house = House.new
    bed   = Bed.new

    new_bed = Bed.new
    Bed.stubs(:new).returns(new_bed)
    new_bed.stubs(:persisted?).returns(false)

    controller = BedsController.new
    controller.instance_variable_set('@parent_type', :house)
    controller.instance_variable_set('@house', house)
    controller.instance_variable_set('@bed', bed)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "house_beds_#{path_or_url}").with(house).once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "house_bed_#{path_or_url}").with(house, bed).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_house_bed_#{path_or_url}").with(house).once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_bed_#{path_or_url}").with(house, bed).once
      controller.send("edit_resource_#{path_or_url}")

      mock_polymorphic(controller, "house_#{path_or_url}").with(house).once
      controller.send("parent_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_#{path_or_url}").with(house).once
      controller.send("edit_parent_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "house_bed_url").with(house, bed, :page => 1).once
    controller.send("resource_url", :page => 1)

    mock_polymorphic(controller, "house_url").with(house, :page => 1).once
    controller.send("parent_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with([:arg, new_bed], {}).once
    controller.send("collection_url", :arg)

    controller.expects("polymorphic_url").with([house, :arg], {}).once
    controller.send("resource_url", :arg)

    controller.expects("edit_polymorphic_url").with([house, :arg], {}).once
    controller.send("edit_resource_url", :arg)

    controller.expects("polymorphic_url").with([:arg], {}).once
    controller.send("parent_url", :arg)
  end

  def test_url_helpers_on_polymorphic_belongs_to_using_uncountable
    sheep  = Sheep.new
    news = News.new

    new_sheep = Sheep.new
    Sheep.stubs(:new).returns(new_sheep)
    new_sheep.stubs(:persisted?).returns(false)

    controller = SheepController.new
    controller.instance_variable_set('@parent_type', :news)
    controller.instance_variable_set('@news', news)
    controller.instance_variable_set('@sheep', sheep)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "news_sheep_index_#{path_or_url}").with(news).once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "news_sheep_#{path_or_url}").with(news, sheep).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_news_sheep_#{path_or_url}").with(news).once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_news_sheep_#{path_or_url}").with(news, sheep).once
      controller.send("edit_resource_#{path_or_url}")

      mock_polymorphic(controller, "news_#{path_or_url}").with(news).once
      controller.send("parent_#{path_or_url}")

      mock_polymorphic(controller, "edit_news_#{path_or_url}").with(news).once
      controller.send("edit_parent_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "news_sheep_url").with(news, sheep, :page => 1).once
    controller.send("resource_url", :page => 1)

    mock_polymorphic(controller, "news_url").with(news, :page => 1).once
    controller.send("parent_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with([:arg, new_sheep], {}).once
    controller.send("collection_url", :arg)

    controller.expects("polymorphic_url").with([news, :arg], {}).once
    controller.send("resource_url", :arg)

    controller.expects("edit_polymorphic_url").with([news, :arg], {}).once
    controller.send("edit_resource_url", :arg)

    controller.expects("polymorphic_url").with([:arg], {}).once
    controller.send("parent_url", :arg)
  end

  def test_url_helpers_on_namespaced_polymorphic_belongs_to
    house = House.new
    desk  = Desk.new

    new_desk = Desk.new
    Desk.stubs(:new).returns(new_desk)
    new_desk.stubs(:persisted?).returns(false)

    controller = Admin::DesksController.new
    controller.instance_variable_set('@parent_type', :house)
    controller.instance_variable_set('@house', house)
    controller.instance_variable_set('@desk', desk)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "admin_house_desks_#{path_or_url}").with(house).once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "admin_house_desk_#{path_or_url}").with(house, desk).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_admin_house_desk_#{path_or_url}").with(house).once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_admin_house_desk_#{path_or_url}").with(house, desk).once
      controller.send("edit_resource_#{path_or_url}")

      mock_polymorphic(controller, "admin_house_#{path_or_url}").with(house).once
      controller.send("parent_#{path_or_url}")

      mock_polymorphic(controller, "edit_admin_house_#{path_or_url}").with(house).once
      controller.send("edit_parent_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "admin_house_desk_url").with(house, desk, :page => 1).once
    controller.send("resource_url", :page => 1)

    mock_polymorphic(controller, "admin_house_url").with(house, :page => 1).once
    controller.send("parent_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with(['admin', :arg, new_desk], {}).once
    controller.send("collection_url", :arg)

    controller.expects("polymorphic_url").with(['admin', house, :arg], {}).once
    controller.send("resource_url", :arg)

    controller.expects("edit_polymorphic_url").with(['admin', house, :arg], {}).once
    controller.send("edit_resource_url", :arg)

    controller.expects("polymorphic_url").with(['admin', :arg], {}).once
    controller.send("parent_url", :arg)
  end

  def test_url_helpers_on_nested_polymorphic_belongs_to
    house = House.new
    table = Table.new
    dish  = Dish.new

    new_dish = Dish.new
    Dish.stubs(:new).returns(new_dish)
    new_dish.stubs(:persisted?).returns(false)

    controller = DishesController.new
    controller.instance_variable_set('@parent_type', :table)
    controller.instance_variable_set('@house', house)
    controller.instance_variable_set('@table', table)
    controller.instance_variable_set('@dish', dish)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "house_table_dishes_#{path_or_url}").with(house, table).once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "house_table_dish_#{path_or_url}").with(house, table, dish).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_house_table_dish_#{path_or_url}").with(house, table).once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_table_dish_#{path_or_url}").with(house, table, dish).once
      controller.send("edit_resource_#{path_or_url}")

      mock_polymorphic(controller, "house_table_#{path_or_url}").with(house, table).once
      controller.send("parent_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_table_#{path_or_url}").with(house, table).once
      controller.send("edit_parent_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "house_table_dish_url").with(house, table, dish, :page => 1).once
    controller.send("resource_url", :page => 1)

    mock_polymorphic(controller, "house_table_url").with(house, table, :page => 1).once
    controller.send("parent_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with([house, table, :arg], {}).once
    controller.send("resource_url", :arg)

    controller.expects("edit_polymorphic_url").with([house, table, :arg], {}).once
    controller.send("edit_resource_url", :arg)

    controller.expects("polymorphic_url").with([house, :arg], {}).once
    controller.send("parent_url", :arg)
  end

  def test_url_helpers_on_singleton_nested_polymorphic_belongs_to
    # This must not be usefull in singleton controllers...
    # Center.new
    house = House.new
    table = Table.new

    controller = CentersController.new
    controller.instance_variable_set('@parent_type', :table)
    controller.instance_variable_set('@house', house)
    controller.instance_variable_set('@table', table)

    # This must not be useful in singleton controllers...
    # controller.instance_variable_set('@center', :center)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "house_table_#{path_or_url}").with(house, table).once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "house_table_center_#{path_or_url}").with(house, table).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_house_table_center_#{path_or_url}").with(house, table).once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_table_center_#{path_or_url}").with(house, table).once
      controller.send("edit_resource_#{path_or_url}")

      mock_polymorphic(controller, "house_table_#{path_or_url}").with(house, table).once
      controller.send("parent_#{path_or_url}")

      mock_polymorphic(controller, "edit_house_table_#{path_or_url}").with(house, table).once
      controller.send("edit_parent_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "house_table_center_url").with(house, table, :page => 1)
    controller.send("resource_url", :page => 1)

    mock_polymorphic(controller, "house_table_url").with(house, table, :page => 1)
    controller.send("parent_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with([house, table, :center], {}).once
    controller.send("resource_url", :arg)

    controller.expects("polymorphic_url").with([house, :arg], {}).once
    controller.send("parent_url", :arg)
  end

  def test_url_helpers_on_optional_polymorphic_belongs_to
    bed   = Bed.new
    new_bed = Bed.new
    Bed.stubs(:new).returns(new_bed)
    new_bed.stubs(:persisted?).returns(false)

    controller = BedsController.new
    controller.instance_variable_set('@parent_type', nil)
    controller.instance_variable_set('@bed', bed)

    [:url, :path].each do |path_or_url|
      mock_polymorphic(controller, "beds_#{path_or_url}").with().once
      controller.send("collection_#{path_or_url}")

      mock_polymorphic(controller, "bed_#{path_or_url}").with(bed).once
      controller.send("resource_#{path_or_url}")

      mock_polymorphic(controller, "new_bed_#{path_or_url}").with().once
      controller.send("new_resource_#{path_or_url}")

      mock_polymorphic(controller, "edit_bed_#{path_or_url}").with(bed).once
      controller.send("edit_resource_#{path_or_url}")
    end

    # With options
    mock_polymorphic(controller, "bed_url").with(bed, :page => 1).once
    controller.send("resource_url", :page => 1)

    # With args
    controller.expects("polymorphic_url").with([:arg], {}).once
    controller.send("resource_url", :arg)

    controller.expects("edit_polymorphic_url").with([:arg], {}).once
    controller.send("edit_resource_url", :arg)
  end


  def test_url_helpers_on_belongs_to_with_shallowed_route
    controller = MirrorsController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@mirror', :mirror)

    [:url, :path].each do |path_or_url|
      controller.expects("house_mirrors_#{path_or_url}").with(:house, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("mirror_#{path_or_url}").with(:mirror, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_house_mirror_#{path_or_url}").with(:house, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_mirror_#{path_or_url}").with(:mirror, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("house_#{path_or_url}").with(:house, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_parent_#{path_or_url}")
    end
  end

  def test_url_helpers_on_nested_belongs_to_with_shallowed_route
    controller = ButtonsController.new
    controller.instance_variable_set('@display', :display)
    controller.instance_variable_set('@window', :window)
    controller.instance_variable_set('@button', :button)

    [:url, :path].each do |path_or_url|
      controller.expects("window_buttons_#{path_or_url}").with(:window, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("button_#{path_or_url}").with(:button, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_window_button_#{path_or_url}").with(:window, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_button_#{path_or_url}").with(:button, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("window_#{path_or_url}").with(:window, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_window_#{path_or_url}").with(:window, {}).once
      controller.send("edit_parent_#{path_or_url}")
    end
  end

  def test_url_helpers_with_custom_actions
    controller = ButtonsController.new
    controller.instance_variable_set('@display', :display)
    controller.instance_variable_set('@window', :window)
    controller.instance_variable_set('@button', :button)
    [:url, :path].each do |path_or_url|
      controller.expects("delete_button_#{path_or_url}").with(:button, {}).once
      controller.send("delete_resource_#{path_or_url}")

      controller.expects("search_window_buttons_#{path_or_url}").with(:window, {}).once
      controller.send("search_resources_#{path_or_url}")
    end
  end

  def test_helper_methods_with_custom_actions
    controller = ButtonsController.new
    helper_methods = controller.class._helpers.instance_methods.map {|m| m.to_s }
    [:url, :path].each do |path_or_url|
      assert helper_methods.include?("delete_resource_#{path_or_url}")
      assert helper_methods.include?("search_resources_#{path_or_url}")
    end
  end

  def test_helpers_on_inherited_controller
    controller = ImageButtonsController.new
    controller.expects("edit_image_button_path").once
    controller.send("edit_resource_path")
    controller.expects("delete_image_button_path").once
    controller.send("delete_resource_path")
  end

  def test_url_helpers_on_namespaced_resource_with_shallowed_route
    controller = Admin::MirrorsController.new
    controller.instance_variable_set('@house', :house)
    controller.instance_variable_set('@mirror', :mirror)

    [:url, :path].each do |path_or_url|

      controller.expects("admin_house_mirrors_#{path_or_url}").with(:house, {}).once
      controller.send("collection_#{path_or_url}")

      controller.expects("admin_mirror_#{path_or_url}").with(:mirror, {}).once
      controller.send("resource_#{path_or_url}")

      controller.expects("new_admin_house_mirror_#{path_or_url}").with(:house, {}).once
      controller.send("new_resource_#{path_or_url}")

      controller.expects("edit_admin_mirror_#{path_or_url}").with(:mirror, {}).once
      controller.send("edit_resource_#{path_or_url}")

      controller.expects("admin_house_#{path_or_url}").with(:house, {}).once
      controller.send("parent_#{path_or_url}")

      controller.expects("edit_admin_house_#{path_or_url}").with(:house, {}).once
      controller.send("edit_parent_#{path_or_url}")
    end
  end
end
