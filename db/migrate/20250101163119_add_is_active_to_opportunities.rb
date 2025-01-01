class AddIsActiveToOpportunities < ActiveRecord::Migration[6.1]
  def change
    add_column :opportunities, :is_active, :boolean, default: true, null: false
  end
end
