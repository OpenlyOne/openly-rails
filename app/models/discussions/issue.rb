# frozen_string_literal: true

module Discussions
  #  Issues in projects
  class Issue < Base
    # Validations
    validates :type, inclusion: { in: %w[Discussions::Issue] }
  end
end
