# frozen_string_literal: true

module VCS
  # A repository-wide unique record for identifying files across branches and
  # versions
  class File < ApplicationRecord
    acts_as_hashids length: 20, secret: ENV['VCS_FILE_HASH_ID_SECRET']

    belongs_to :repository
    has_many :thumbnails, dependent: :destroy

    has_many :repository_branches, through: :repository, source: :branches

    has_many :versions, dependent: :destroy
    has_many :versions_of_children,
             class_name: 'VCS::Version',
             foreign_key: :parent_id,
             dependent: :destroy

    # Convert a single hashed ID to ID
    # If InputError is encountered, returns nil
    def self.hashid_to_id(hashid)
      hashids.decode(hashid.to_s)&.first
    rescue Hashids::InputError
      nil
    end
  end
end
