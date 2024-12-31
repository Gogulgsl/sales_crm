class CreateSalesTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :sales_teams do |t|
      t.bigint :user_id, null: false
      t.bigint :manager_user_id
      t.bigint :createdby_user_id
      t.bigint :updatedby_user_id

      t.timestamps
    end

    add_index :sales_teams, :user_id, unique: true
    add_index :sales_teams, :createdby_user_id
    add_index :sales_teams, :updatedby_user_id
    add_index :sales_teams, :manager_user_id

    add_foreign_key :sales_teams, :users
    add_foreign_key :sales_teams, :users, column: :manager_user_id
    add_foreign_key :sales_teams, :users, column: :createdby_user_id
    add_foreign_key :sales_teams, :users, column: :updatedby_user_id
  end
end
