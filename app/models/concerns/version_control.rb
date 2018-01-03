# frozen_string_literal: true

# Git Repository association handlers
module VersionControl
  extend ActiveSupport::Concern

  # Callbacks
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

  # Delegations
  delegate :stage, to: :repository, prefix: :repository, allow_nil: true
  delegate :files, to: :repository_stage, allow_nil: true
  delegate :revisions, to: :repository, allow_nil: true

  # When reloading object, also reset repository
  def reload
    @repository = nil
    super
  end

  # Return the project's Git repository
  def repository
    return nil if repository_file_path.nil?
    @repository ||= VersionControl::Repository.find repository_file_path
  end

  private

  # Create a new Git repository
  def create_repository
    @repository = VersionControl::Repository.create repository_file_path
  end

  # Destroy a Git repository
  def destroy_repository
    FileUtils.rm_rf repository_file_path
    @repository = nil
  end
end
