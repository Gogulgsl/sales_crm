class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :password_digest
      t.string :email
      t.string :mobile_number
      t.string :role
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    add_index :users, :createdby_user_id
    add_index :users, :updatedby_user_id
  end
end
