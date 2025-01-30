class ChangeStartDateNullInOpportunityLogs < ActiveRecord::Migration[6.1]
  def change
    change_column_null :opportunity_logs, :start_date, true
  end
end
