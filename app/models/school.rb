class School < ApplicationRecord
  # Associations
  belongs_to :group_school, class_name: 'School', optional: true
  belongs_to :created_by, class_name: 'User', foreign_key: :createdby_user_id, optional: true
  belongs_to :updated_by, class_name: 'User', foreign_key: :updatedby_user_id, optional: true
  has_many :contacts
  accepts_nested_attributes_for :contacts, allow_destroy: true
  # Validations
  validates :name, presence: true
  validates :location, presence: true
  validates :city, presence: true
  validates :state, presence: true
  # validates :pincode, presence: true, format: { with: /\A\d{5,6}\z/, message: 'must be a valid pincode' }
  # validates :number_of_students, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  # validates :avg_fees, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  # validates :group_school_id, presence: true, if: :part_of_group_school?

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Callbacks
  before_save :normalize_fields

  private

  # Ensure the group_school exists if `part_of_group_school` is true
  def group_school_should_exist_if_flagged
    if part_of_group_school && group_school_id.nil?
      errors.add(:group_school_id, 'must be provided if the school is part of a group')
    end
  end

  # Normalize fields before saving (titleize names, location, etc.)
  def normalize_fields
    self.name = name.strip.titleize if name.present?
    self.location = location.strip.titleize if location.present?
    self.city = city.strip.titleize if city.present?
    self.state = state.strip.titleize if state.present?
  end
end
