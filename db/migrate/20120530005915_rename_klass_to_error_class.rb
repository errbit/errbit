class RenameKlassToErrorClass < Mongoid::Migration
  def self.up
    [Problem, Err, Notice].each do |model|
      model.collection.find.update({'$rename' => {'klass' => 'error_class'}}, :multi => true, :safe => true)
    end
  end

  def self.down
    [Problem, Err, Notice].each do |model|
      model.collection.find.update({'$rename' => {'error_class' => 'klass'}}, :multi => true, :safe => true)
    end
  end
end
