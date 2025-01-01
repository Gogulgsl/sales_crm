class RenameMailIdToEmailInDailyStatuses < ActiveRecord::Migration[6.1]
  def change
    rename_column :daily_statuses, :mail_id, :email
  end
end
