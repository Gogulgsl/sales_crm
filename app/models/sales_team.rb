class SalesTeam < ApplicationRecord
  # Associations
  belongs_to :user, foreign_key: :user_id, inverse_of: :sales_team
  belongs_to :manager, class_name: 'User', foreign_key: :manager_id, optional: true, inverse_of: :managed_sales_teams
  
  has_many :daily_statuses, foreign_key: :user_id, inverse_of: :sales_team
  has_many :opportunities, foreign_key: :user_id, inverse_of: :sales_team

  # Ensure the user association is unique since it's indexed as unique in the schema
  validates :user_id, uniqueness: true
end
