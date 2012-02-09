require 'spec_helper'

module ToXMLWithNamespaces

  #
  # Similar example as the to_xml but this time with namespacing
  #
  class Address
    include HappyMapper

    register_namespace 'address', 'http://www.company.com/address'
    register_namespace 'country', 'http://www.company.com/country'

    tag 'Address'
    namespace 'address'

    element :country, 'Country', :tag => 'country', :namespace => 'country'


    attribute :location, String

    element :street, String
    element :postcode, String
    element :city, String

    element :housenumber, String

    #
    # to_xml will default to the attr_accessor method and not the attribute,
    # allowing for that to be overwritten
    #
    def housenumber
      "[#{@housenumber}]"
    end

    #
    # Write a empty element even if this is not specified
    #
    element :description, String, :state_when_nil => true

    #
    # Perform the on_save operation when saving
    #
    has_one :date_created, Time, :on_save => lambda {|time| DateTime.parse(time).strftime("%T %D") if time }

    #
    # Write multiple elements and call on_save when saving
    #
    has_many :dates_updated, Time, :on_save => lambda {|times|
      times.compact.map {|time| DateTime.parse(time).strftime("%T %D") } if times }

    #
    # Class composition
    #

    def initialize(parameters)
      parameters.each_pair do |property,value|
        send("#{property}=",value) if respond_to?("#{property}=")
      end
    end

  end

  #
  # Country is composed above the in Address class. Here is a demonstration
  # of how to_xml will handle class composition as well as utilizing the tag
  # value.
  #
  class Country
    include HappyMapper

    register_namespace 'countryName', 'http://www.company.com/countryName'

    attribute :code, String, :tag => 'countryCode'
    has_one :name, String, :tag => 'countryName', :namespace => 'countryName'

    def initialize(parameters)
      parameters.each_pair do |property,value|
        send("#{property}=",value) if respond_to?("#{property}=")
      end
    end

  end

  describe "#to_xml" do

    context "Address" do

      before(:all) do
        address = Address.new('street' => 'Mockingbird Lane',
        'location' => 'Home',
        'housenumber' => '1313',
        'postcode' => '98103',
        'city' => 'Seattle',
        'country' => Country.new(:name => 'USA', :code => 'us'),
        'date_created' => '2011-01-01 15:00:00')

        address.dates_updated = ["2011-01-01 16:01:00","2011-01-02 11:30:01"]

        @address_xml = XML::Parser.string(address.to_xml).parse.root
      end

      { 'street' => 'Mockingbird Lane',
        'postcode' => '98103',
        'city' => 'Seattle' }.each_pair do |property,value|

        it "should have the element '#{property}' with the value '#{value}'" do
          @address_xml.find("address:#{property}").first.child.to_s.should == value
        end

      end

      it "should use the result of #housenumber method (not the @housenumber)" do
        @address_xml.find("address:housenumber").first.child.to_s.should == "[1313]"
      end

      it "should have the attribute 'location' with the value 'Home'" do
        @address_xml.find('@location').first.child.to_s.should == "Home"
      end

      it "should add an empty description element" do
        @address_xml.find('address:description').first.child.to_s.should == ""
      end

      it "should call #on_save when saving the time to convert the time" do
        @address_xml.find('address:date_created').first.child.to_s.should == "15:00:00 01/01/11"
      end

      it "should handle multiple elements for 'has_many'" do
        dates_updated = @address_xml.find('address:dates_updated')
        dates_updated.length.should == 2
        dates_updated.first.child.to_s.should == "16:01:00 01/01/11"
        dates_updated.last.child.to_s.should == "11:30:01 01/02/11"
      end

      it "should write the country code" do
        @address_xml.find('country:country/@country:countryCode').first.child.to_s.should == "us"
      end

      it "should write the country name" do
        @address_xml.find('country:country/countryName:countryName').first.child.to_s.should == "USA"
      end

    end


  end

end