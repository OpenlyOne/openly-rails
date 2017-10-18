# frozen_string_literal: true

module Discussions
  #  Issues in projects
  class Question < Base
    # Associations
    belongs_to :project, class_name: 'Project', counter_cache: true

    # Validations
    validates :type, inclusion: { in: %w[Discussions::Question] }
  end
end
