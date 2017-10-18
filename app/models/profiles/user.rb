# frozen_string_literal: true

module Profiles
  # Every account has a user. The user model handles the aspects that are
  # visible to other users, such as the user's name (as opposed to an account's
  # email and password, for example)
  class User < Base
    # Adopt route key of Profiles::Base class
    # See: https://stackoverflow.com/a/9463495/6451879
    def self.model_name
      Base.model_name
    end

    # Associations
    belongs_to :account
    has_many :discussions, class_name: 'Discussions::Base',
                           dependent: :destroy,
                           foreign_key: :initiator_id,
                           inverse_of: :initiator
    has_many :replies, dependent: :destroy,
                       foreign_key: :author_id,
                       inverse_of: :author

    # Attributes
    # Do not allow account change
    attr_readonly :account_id

    # Get handle of user (username)
    def username
      try(:handle).try(:identifier)
    end
  end
end
