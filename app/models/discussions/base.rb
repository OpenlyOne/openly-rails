# frozen_string_literal: true

module Discussions
  # STI parent class for suggestions, issues, and questions
  class Base < ApplicationRecord
    self.table_name = 'discussions'

    # Scoped IDs
    acts_as_sequenced scope: :project_id, column: :scoped_id

    # Associations
    belongs_to :initiator, class_name: 'User'
    belongs_to :project, class_name: 'Project'

    # Validations
    validates :title, presence: true, length: { maximum: 100 }

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
