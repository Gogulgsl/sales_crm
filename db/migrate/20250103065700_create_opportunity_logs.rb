class CreateOpportunityLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :opportunity_logs do |t|
      t.bigint :opportunity_id, null: false
      t.bigint :school_id, null: false
      t.bigint :product_id, null: false
      t.datetime :start_date, null: false
      t.string :opportunity_name
      t.bigint :user_id
      t.string :last_stage
      t.string :previous_stage 
      t.bigint :contact_id
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id
      t.boolean :is_active, default: true, null: false
      t.string :zone
      t.bigint :changed_by_user_id 
      t.timestamps
    end

    add_index :opportunity_logs, :opportunity_id
    add_index :opportunity_logs, :school_id
    add_index :opportunity_logs, :product_id
    add_index :opportunity_logs, :user_id
    add_index :opportunity_logs, :contact_id
  end
end
