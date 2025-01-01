class DailyStatus < ApplicationRecord
  belongs_to :user
  belongs_to :opportunity
  belongs_to :school, optional: true
  belongs_to :decision_maker_contact, class_name: 'Contact', foreign_key: 'decision_maker_contact_id', optional: true
  belongs_to :person_met_contact, class_name: 'Contact', foreign_key: 'person_met_contact_id', optional: true
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'createdby_user_id', optional: true
  belongs_to :updated_by_user, class_name: 'User', foreign_key: 'updatedby_user_id', optional: true

  # Validations
  validates :user_id, :opportunity_id, presence: true
  validates :follow_up, :discussion_point, :next_steps, :stage, presence: true
end
