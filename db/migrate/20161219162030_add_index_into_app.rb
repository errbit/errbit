require 'mongoid'
class AddIndexIntoApp < Mongoid::Migration
  def self.up
    App.create_indexes
  end

  def self.down

  end
end