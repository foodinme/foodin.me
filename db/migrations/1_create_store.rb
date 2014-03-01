Sequel.migration do
  change do
    create_table :sessions do
      String :key, null: false
      String :data, text: true
    end
  end
end
