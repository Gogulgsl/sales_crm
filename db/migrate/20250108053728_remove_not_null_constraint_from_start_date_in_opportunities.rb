class RemoveNotNullConstraintFromStartDateInOpportunities < ActiveRecord::Migration[6.1]
  def change
    change_column_null :opportunities, :start_date, true
  end
end
