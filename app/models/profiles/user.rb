# frozen_string_literal: true

module Profiles
  # Every account has a user. The user model handles the aspects that are
  # visible to other users, such as the user's name (as opposed to an account's
  # email and password, for example)
  class User < Base
    acts_as_notifier

    # Associations
    belongs_to :account
    has_many :visits, class_name: 'Ahoy::Visit'

    # Attributes
    # Do not allow account change
    attr_readonly :account_id

    # Delegations
    delegate :admin?, to: :account
  end
end
