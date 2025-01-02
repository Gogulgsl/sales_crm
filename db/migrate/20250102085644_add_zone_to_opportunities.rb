class AddZoneToOpportunities < ActiveRecord::Migration[6.1]
  def change
    add_column :opportunities, :zone, :string
  end
end
