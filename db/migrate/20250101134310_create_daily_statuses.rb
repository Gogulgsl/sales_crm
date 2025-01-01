class CreateDailyStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :daily_statuses do |t|
      t.bigint :user_id, null: false
      t.bigint :opportunity_id, null: false
      t.text :follow_up
      t.string :designation
      t.string :mail_id
      t.text :discussion_point
      t.text :next_steps
      t.string :stage
      t.bigint :decision_maker_contact_id
      t.bigint :person_met_contact_id
      t.bigint :school_id
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    # Add indexes
    add_index :daily_statuses, :user_id
    add_index :daily_statuses, :opportunity_id
    add_index :daily_statuses, :decision_maker_contact_id
    add_index :daily_statuses, :person_met_contact_id
    add_index :daily_statuses, :school_id
    add_index :daily_statuses, :createdby_user_id
    add_index :daily_statuses, :updatedby_user_id

    # Add foreign keys
    add_foreign_key :daily_statuses, :users
    add_foreign_key :daily_statuses, :opportunities
    add_foreign_key :daily_statuses, :contacts, column: :decision_maker_contact_id
    add_foreign_key :daily_statuses, :contacts, column: :person_met_contact_id
    add_foreign_key :daily_statuses, :schools
    add_foreign_key :daily_statuses, :users, column: :createdby_user_id
    add_foreign_key :daily_statuses, :users, column: :updatedby_user_id
  end
end
