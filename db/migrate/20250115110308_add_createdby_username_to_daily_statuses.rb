class AddCreatedbyUsernameToDailyStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_statuses, :createdby_username, :string
  end
end
