class CreateContacts < ActiveRecord::Migration[6.1]
  def change
    create_table :contacts do |t|
      t.string :contact_name
      t.string :mobile
      t.boolean :decision_maker, default: false
      t.bigint :school_id, null: false
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    # Add indexes for foreign keys
    add_index :contacts, :school_id, name: "index_contacts_on_school_id"
    add_index :contacts, :createdby_user_id, name: "index_contacts_on_createdby_user_id"
    add_index :contacts, :updatedby_user_id, name: "index_contacts_on_updatedby_user_id"

    # Add foreign key constraints
    add_foreign_key :contacts, :schools
    add_foreign_key :contacts, :users, column: :createdby_user_id
    add_foreign_key :contacts, :users, column: :updatedby_user_id
  end
end
