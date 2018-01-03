# frozen_string_literal: true

# Git Repository association handlers
module VersionControl
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
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

    # Safely rename/move repository when repository_file_path changes
    before_update do
      # Save the repository_file_path before update
      @repository_file_path_before_update = repository_file_path
    end
    after_update do
      # exit if the repository file path has not changed
      next if repository_file_path == @repository_file_path_before_update

      # otherwise: rename repository
      begin
        rename_repository(
          @repository_file_path_before_update,  # old path
          repository_file_path                  # new path
        )
      rescue
        # Do not persist object if any errors occur while renaming repository
        raise ActiveRecord::Rollback
      end
    end

    # Also delete repository when parent is deleted
    after_destroy do
      begin
        destroy_repository
      rescue
        # Do not persist object if any errors occur while destroying repository
        raise ActiveRecord::Rollback
      end
    end
  end
  # rubocop:enable Metrics/BlockLength

  # Return the project's Git repository
  def repository
    @repository ||= VersionControl::Repository.find repository_file_path
  end

  private

  # Create a new Git repository
  def create_repository
    @repository = VersionControl::Repository.create repository_file_path
  end

  # Rename a Git repository
  def rename_repository(old_path, new_path)
    @repository = VersionControl::Repository.find(old_path).rename(new_path)
  end

  # Destroy a Git repository
  def destroy_repository
    FileUtils.rm_rf repository_file_path
    @repository = nil
  end
end
