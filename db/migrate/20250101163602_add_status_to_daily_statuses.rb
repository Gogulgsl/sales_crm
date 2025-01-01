class AddStatusToDailyStatuses < ActiveRecord::Migration[6.1]
  def change
    add_column :daily_statuses, :status, :string, default: "pending"
  end
end
