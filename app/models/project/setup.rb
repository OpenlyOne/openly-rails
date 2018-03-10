# frozen_string_literal: true

class Project
  # Track setup process of a project (primarily file import)
  class Setup < ApplicationRecord
    # Associations
    belongs_to :project

    # Validations
    validates :project_id, uniqueness: { message: 'has already been set up' }
  end
end
