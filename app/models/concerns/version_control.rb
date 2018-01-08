# frozen_string_literal: true

# Git Repository association handlers
module VersionControl
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    # Delegations
    delegate :stage, to: :repository, prefix: :repository, allow_nil: true
    delegate :files, to: :repository_stage, allow_nil: true
    delegate :revisions, to: :repository, allow_nil: true

    # Callbacks
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

    # Find each repository within the repository folder, initialize it, and
    # yield it to the passed block. Accepts an optional parameter :lock that
    # will lock each repository before yielding it.
    def self.find_each_repository(lock_each = nil, &_block)
      # One by one, find each repository within the repository folder path
      Pathname(repository_folder_path).children.each do |path|
        # Initialize the repository at path
        repository = VersionControl::Repository.find(path.realpath.to_s)

        # Lock and yield repository
        if lock_each == :lock
          repository.lock { yield(repository) }

        # Just yield repository
        else
          yield(repository)
        end
      end
    rescue Errno::ENOENT
      # If repository folder path does not exist, just do nothing
      nil
    end
  end
  # rubocop:enable Metrics/BlockLength

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
