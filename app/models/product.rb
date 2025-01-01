class Product < ApplicationRecord
  validates :product_name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  serialize :available_days, Array
end
