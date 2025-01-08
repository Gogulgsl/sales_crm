class Opportunity < ApplicationRecord
  belongs_to :school
  belongs_to :product
  belongs_to :user, optional: true 
  belongs_to :contact, optional: true
  # validates :start_date, presence: true
  validates :user, presence: true

  has_many :daily_statuses
  has_many :opportunity_logs, dependent: :destroy
  before_update :log_stage_change

  private

  def log_stage_change
    if last_stage_changed?
      OpportunityLog.create!(
        opportunity_id: id,
        school_id: school_id,
        product_id: product_id,
        start_date: start_date,
        opportunity_name: opportunity_name,
        user_id: user_id,
        contact_id: contact_id,
        zone: zone,
        is_active: is_active,
        createdby_user_id: createdby_user_id,
        updatedby_user_id: updatedby_user_id,
        previous_stage: last_stage_was, # Capture the previous value
        last_stage: last_stage,        # Capture the new value
        changed_by_user_id: updatedby_user_id, # User making the change
        created_at: Time.current       # Log entry creation time
      )
    end
  end
end


