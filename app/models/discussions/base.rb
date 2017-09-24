# frozen_string_literal: true

module Discussions
  # STI parent class for suggestions, issues, and questions
  class Base < ApplicationRecord
    self.table_name = 'discussions'

    # Associations
    belongs_to :initiator, class_name: 'User'
    belongs_to :project, class_name: 'Project'

    # Validations
    validates :title, presence: true, length: { maximum: 100 }

    # Convert the type to the format of URL segment (e.g. 'suggestions')
    def type_to_url_segment
      type.split('::').last.downcase.pluralize
    end
  end
end
