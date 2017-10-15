# frozen_string_literal: true

module Discussions
  #  Issues in projects
  class Issue < Base
    # Associations
    belongs_to :project, class_name: 'Project', counter_cache: true

    # Validations
    validates :type, inclusion: { in: %w[Discussions::Issue] }
  end
end
