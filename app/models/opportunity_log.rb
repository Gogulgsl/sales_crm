class OpportunityLog < ApplicationRecord
  belongs_to :opportunity
  belongs_to :school, optional: true
  belongs_to :product, optional: true
  belongs_to :user, optional: true
  belongs_to :contact, optional: true
end