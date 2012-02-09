dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/pita.xml')

# The document `pita.xml` contains both a default namespace and the 'georss'
# namespace (for the 'point' element).
module PITA
  class Item
    include HappyMapper
    
    tag 'Item' # if you put class in module you need tag
    element :asin, String, :tag => 'ASIN'
    element :detail_page_url, String, :tag => 'DetailPageURL'
    element :manufacturer, String, :tag => 'Manufacturer', :deep => true
    # this is the only element that exists in a different namespace, so it
    # must be explicitly specified
    element :point, String, :tag => 'point', :namespace => 'georss'
  end

  class Items
    include HappyMapper
    
    tag 'Items' # if you put class in module you need tag
    element :total_results, Integer, :tag => 'TotalResults'
    element :total_pages, Integer, :tag => 'TotalPages'
    has_many :items, Item
  end
end

item = PITA::Items.parse(file_contents, :single => true)
item.items.each do |i|
  puts i.asin, i.detail_page_url, i.manufacturer, ''
end