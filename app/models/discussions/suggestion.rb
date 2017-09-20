# frozen_string_literal: true

module Discussions
  #  Suggestions in projects
  class Suggestion < Base
    # Validations
    validates :type, inclusion: { in: %w[Discussions::Suggestion] }
  end
end
