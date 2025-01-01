class AddIsActiveToProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :is_active, :boolean, default: true, null: false
  end
end
