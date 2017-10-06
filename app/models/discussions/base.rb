# frozen_string_literal: true

module Discussions
  # STI parent class for suggestions, issues, and questions
  class Base < ApplicationRecord
    self.table_name = 'discussions'

    # Scoped IDs
    acts_as_sequenced scope: :project_id, column: :scoped_id

    # Prepended Validation (we want to validate title prior to initial reply)
    validates :title, presence: true, length: { maximum: 100 }

    # Associations
    belongs_to :initiator, class_name: 'User'
    belongs_to :project, class_name: 'Project'
    has_one :initial_reply,
            -> { order(:id).limit(1) },
            class_name: 'Reply',
            dependent: :destroy,
            inverse_of: :discussion,
            foreign_key: 'discussion_id'
    has_many :replies,
             -> { order(:id).offset(1) },
             dependent: :destroy,
             inverse_of: :discussion,
             foreign_key: 'discussion_id'

    # Attributes
    accepts_nested_attributes_for :initial_reply

    # Validations
    validates :initial_reply, presence: true

    # Use scoped ID as param in URLs
    def to_param
      scoped_id
    end

    # Convert the type to the format of URL segment (e.g. 'suggestions')
    def type_to_url_segment
      type.split('::').last.downcase.pluralize
    end
  end
end
