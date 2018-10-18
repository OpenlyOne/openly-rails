# frozen_string_literal: true

class Project
  # The archive for storing file backups, just like a .git folder
  class Archive < ApplicationRecord
    # Associations
    belongs_to :project
    belongs_to :file_resource

    # Validations
    validates :project_id, uniqueness: { message: 'already has an archive' }
  end
end
