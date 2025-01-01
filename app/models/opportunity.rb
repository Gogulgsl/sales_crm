class Opportunity < ApplicationRecord
  belongs_to :school
  belongs_to :product
  belongs_to :user, optional: true 
  belongs_to :contact, optional: true
  validates :start_date, presence: true
  validates :user, presence: true

  has_many :daily_statuses
end


