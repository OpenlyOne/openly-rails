# frozen_string_literal: true

module Discussions
  #  Issues in projects
  class Question < Base
    # Validations
    validates :type, inclusion: { in: %w[Discussions::Question] }
  end
end
