class User < ApplicationRecord
  # Secure password handling
  has_secure_password

  # Associations
  has_one :sales_team, dependent: :destroy
  has_many :opportunities, dependent: :nullify
  belongs_to :manager_user, class_name: 'User', foreign_key: 'reporting_manager_id', optional: true  # Correct association

  # Validations
  validates :username, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :role, presence: true, inclusion: { in: %w[admin sales_executive manager] }
  validates :email, presence: true, uniqueness: true

  private

  def password_required?
    new_record? || !password.nil?
  end
end
