require 'sequel'

DB = Sequel.sqlite # in memory
Sequel.extension :migration
Sequel::Migrator.run(DB, 'spec/support/sequel_migrations', :current => 0)

class ChildSequelModel < Sequel::Model
  many_to_one :parent, :class => :ParentSequelModel, :key => :parent_sequel_model_id

  def persisted?; !new? end
end

class ParentSequelModel < Sequel::Model
  one_to_many :collection_field, :class => :ChildSequelModel, :key => :parent_sequel_model_id

  def persisted?; !new? end

  def before_save
    self.before_save_value = 11
    super
  end
end
