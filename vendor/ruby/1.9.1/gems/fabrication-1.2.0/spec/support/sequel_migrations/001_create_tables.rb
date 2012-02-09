Sequel.migration do
  up do
    create_table :child_sequel_models do
      primary_key :id
      Integer :parent_sequel_model_id
      Integer :number_field
    end

    create_table :parent_sequel_models do
      primary_key :id
      Integer :before_save_value
      String :dynamic_field
      String :nil_field
      Integer :number_field
      String :string_field
    end
  end

  down do
    drop_table :child_sequel_models
    drop_table :parent_sequel_models
  end
end
