class Contact < ApplicationRecord
  belongs_to :school
  belongs_to :created_by, class_name: 'User', foreign_key: 'createdby_user_id', optional: true
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updatedby_user_id', optional: true

  validates :contact_name, presence: true
  validates :mobile, presence: true, format: { with: /\A\d{10}\z/, message: "must be 10 digits" }
end