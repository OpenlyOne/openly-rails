# frozen_string_literal: true

# Top level model responsible for registration, authentication, settings, ...
# Is never exposed to anyone but the account owner
class Account < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable

  # Do not allow email change
  attr_readonly :email
end
