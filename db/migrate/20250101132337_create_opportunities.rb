class CreateOpportunities < ActiveRecord::Migration[6.1]
  def change
    create_table :opportunities do |t|
      t.bigint :school_id, null: false
      t.bigint :product_id, null: false
      t.datetime :start_date, null: false
      t.string :opportunity_name
      t.bigint :user_id
      t.string :last_stage
      t.bigint :contact_id
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    # Add indexes for foreign keys
    add_index :opportunities, :school_id, name: "index_opportunities_on_school_id"
    add_index :opportunities, :product_id, name: "index_opportunities_on_product_id"
    add_index :opportunities, :user_id, name: "index_opportunities_on_user_id"
    add_index :opportunities, :contact_id, name: "index_opportunities_on_contact_id" # Add index for contact_id if frequently queried

    # Add foreign key constraints
    add_foreign_key :opportunities, :schools
    add_foreign_key :opportunities, :products
    add_foreign_key :opportunities, :contacts
    add_foreign_key :opportunities, :users
    add_foreign_key :opportunities, :users, column: :createdby_user_id
    add_foreign_key :opportunities, :users, column: :updatedby_user_id
  end
end
