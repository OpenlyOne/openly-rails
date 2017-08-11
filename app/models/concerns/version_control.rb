# frozen_string_literal: true

# Git Repository association handlers
module VersionControl
  extend ActiveSupport::Concern

  included do
    # Safely create repository after creating object
    after_create do
      begin
        create_repository
      rescue
        # Do not persist object if any errors occur while creating repository
        raise ActiveRecord::Rollback
      end
    end
  end

  # Return the project's Git repository
  def repository
    @repository ||= VersionControl::Repository.find repository_file_path
  end

  private

  # Create a new Git repository
  def create_repository
    @repository = VersionControl::Repository.create repository_file_path, :bare
  end
end
