# frozen_string_literal: true

# Every account has a user. The user model handles the aspects that are visible
# to other users, such as the user's name (as opposed to an account's email and
# password, for example)
class User < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
end
