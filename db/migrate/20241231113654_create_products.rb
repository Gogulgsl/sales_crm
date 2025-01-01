class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :product_name
      t.text :description
      t.string :supplier
      t.string :unit
      t.decimal :price, precision: 10, scale: 2
      t.datetime :date
      t.json :available_days, default: []
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    add_index :products, :createdby_user_id, name: "index_products_on_createdby_user_id"
    add_index :products, :updatedby_user_id, name: "index_products_on_updatedby_user_id"

    add_foreign_key :products, :users, column: :createdby_user_id
    add_foreign_key :products, :users, column: :updatedby_user_id
  end
end
