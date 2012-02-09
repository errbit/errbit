module Analytics
  class Property
    include HappyMapper

    tag 'property'
    namespace 'http://schemas.google.com/analytics/2009'
    attribute :name, String
    attribute :value, String
  end

  class Entry
    include HappyMapper

    tag 'entry'
    element :id, String
    element :updated, DateTime
    element :title, String
    element :table_id, String, :namespace => 'http://schemas.google.com/analytics/2009', :tag => 'tableId'
    has_many :properties, Property
  end

  class Feed
    include HappyMapper

    tag 'feed'
    element :id, String
    element :updated, DateTime
    element :title, String
    has_many :entries, Entry
  end
end

class Feature
  include HappyMapper
  element :name, String, :tag => '.|.//text()'
end

class FeatureBullet
  include HappyMapper

  tag 'features_bullets'
  has_many :features, Feature
  element :bug, String
end

class Product
  include HappyMapper

  element :title, String
  has_one :feature_bullets, FeatureBullet
end

module FamilySearch
  class Person
    include HappyMapper

    attribute :version, String
    attribute :modified, Time
    attribute :id, String
  end

  class Persons
    include HappyMapper
    has_many :person, Person
  end

  class FamilyTree
    include HappyMapper

    tag 'familytree'
    attribute :version, String
    attribute :status_message, String, :tag => 'statusMessage'
    attribute :status_code, String, :tag => 'statusCode'
    has_one :persons, Persons
  end
end

module FedEx
  class Address
    include HappyMapper

    tag 'Address'
    namespace 'http://fedex.com/ws/track/v2'
    element :city, String, :tag => 'City'
    element :state, String, :tag => 'StateOrProvinceCode'
    element :zip, String, :tag => 'PostalCode'
    element :countrycode, String, :tag => 'CountryCode'
    element :residential, Boolean, :tag => 'Residential'
  end

  class Event
    include HappyMapper

    tag 'Events'
    namespace 'http://fedex.com/ws/track/v2'
    element :timestamp, String, :tag => 'Timestamp'
    element :eventtype, String, :tag => 'EventType'
    element :eventdescription, String, :tag => 'EventDescription'
    has_one :address, Address
  end

  class PackageWeight
    include HappyMapper

    tag 'PackageWeight'
    namespace 'http://fedex.com/ws/track/v2'
    element :units, String, :tag => 'Units'
    element :value, Integer, :tag => 'Value'
  end

  class TrackDetails
    include HappyMapper

    tag 'TrackDetails'
    namespace 'http://fedex.com/ws/track/v2'
    element   :tracking_number, String, :tag => 'TrackingNumber'
    element   :status_code, String, :tag => 'StatusCode'
    element   :status_desc, String, :tag => 'StatusDescription'
    element   :carrier_code, String, :tag => 'CarrierCode'
    element   :service_info, String, :tag => 'ServiceInfo'
    has_one   :weight, PackageWeight, :tag => 'PackageWeight'
    element   :est_delivery,  String, :tag => 'EstimatedDeliveryTimestamp'
    has_many  :events, Event
  end

  class Notification
    include HappyMapper

    tag 'Notifications'
    namespace 'http://fedex.com/ws/track/v2'
    element :severity, String, :tag => 'Severity'
    element :source, String, :tag => 'Source'
    element :code, Integer, :tag => 'Code'
    element :message, String, :tag => 'Message'
    element :localized_message, String, :tag => 'LocalizedMessage'
  end

  class TransactionDetail
    include HappyMapper

    tag 'TransactionDetail'
    namespace 'http://fedex.com/ws/track/v2'
    element :cust_tran_id, String, :tag => 'CustomerTransactionId'
  end

  class TrackReply
    include HappyMapper

    tag 'TrackReply'
    namespace 'http://fedex.com/ws/track/v2'
    element   :highest_severity, String, :tag => 'HighestSeverity'
    element   :more_data, Boolean, :tag => 'MoreData'
    has_many  :notifications, Notification, :tag => 'Notifications'
    has_many  :trackdetails, TrackDetails, :tag => 'TrackDetails'
    has_one   :tran_detail, TransactionDetail, :tab => 'TransactionDetail'
  end
end

class Place
  include HappyMapper
  element :name, String
end

class Radar
  include HappyMapper
  has_many :places, Place
end

class Post
  include HappyMapper

  attribute :href, String
  attribute :hash, String
  attribute :description, String
  attribute :tag, String
  attribute :time, Time
  attribute :others, Integer
  attribute :extended, String
end

class User
  include HappyMapper

  element :id, Integer
  element :name, String
  element :screen_name, String
  element :location, String
  element :description, String
  element :profile_image_url, String
  element :url, String
  element :protected, Boolean
  element :followers_count, Integer

  attr_accessor :after_parse_called
  attr_accessor :after_parse2_called

  after_parse do |doc|
    doc.after_parse_called = true
  end

  after_parse do |doc|
    doc.after_parse2_called = true
  end
end

class Status
  include HappyMapper

  element :id, Integer
  element :text, String
  element :created_at, Time
  element :source, String
  element :truncated, Boolean
  element :in_reply_to_status_id, Integer
  element :in_reply_to_user_id, Integer
  element :favorited, Boolean
  element :non_existent, String, :tag => 'dummy', :namespace => 'fake'
  has_one :user, User
end

class CurrentWeather
  include HappyMapper

  tag 'ob'
  namespace 'http://www.aws.com/aws'
  element :temperature, Integer, :tag => 'temp'
  element :feels_like, Integer, :tag => 'feels-like'
  element :current_condition, String, :tag => 'current-condition', :attributes => {:icon => String}
end

class Address
  include HappyMapper

  tag 'address'
  element :street, String
  element :postcode, String
  element :housenumber, String
  element :city, String
  element :country, String
end

class MultiStreetAddress
  include HappyMapper
  
  tag 'address'
  # allow primitive type to be collection
  has_many :street_address, String, :tag => "streetaddress"
  element :city, String
  element :state_or_providence, String, :tag => "stateOfProvidence"
  element :zip, String
  element :country, String
end

# for type coercion
class ProductGroup < String; end

module PITA
  class Item
    include HappyMapper

    tag 'Item' # if you put class in module you need tag
    element :asin, String, :tag => 'ASIN'
    element :detail_page_url, URI, :tag => 'DetailPageURL', :parser => :parse
    element :manufacturer, String, :tag => 'Manufacturer', :deep => true
    element :point, String, :tag => 'point', :namespace => 'http://www.georss.org/georss'
    element :product_group, ProductGroup, :tag => 'ProductGroup', :deep => true, :parser => :new, :raw => true
  end

  class Items
    include HappyMapper

    tag 'Items' # if you put class in module you need tag
    element :total_results, Integer, :tag => 'TotalResults'
    element :total_pages, Integer, :tag => 'TotalPages'
    has_many :items, Item
  end
end

module GitHub
  class Commit
    include HappyMapper

    tag "commit"
    element :url, String
    element :tree, String
    element :message, String
    element :id, String
    element :'committed-date', Date
  end
end

module Backpack
  class Note
    include HappyMapper

    attribute :id, Integer
    attribute :title, String
    attribute :created_at, Date

    content :body
  end
end