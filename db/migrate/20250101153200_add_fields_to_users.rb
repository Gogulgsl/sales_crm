class AddFieldsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :reporting_manager_id, :bigint
    add_column :users, :is_active, :boolean, default: true, null: false
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
  end
end
