# frozen_string_literal: true

# Top level model responsible for registration, authentication, settings, ...
# Is never exposed to anyone but the account owner
class Account < ApplicationRecord
  # Associations
  has_one :user, dependent: :destroy

  # Devise
  devise :database_authenticatable, :registerable

  # Attributes
  accepts_nested_attributes_for :user
  # Do not allow email change
  attr_readonly :email

  # Validations
  validates :user, presence: true, on: :create
  devise :validatable
end
