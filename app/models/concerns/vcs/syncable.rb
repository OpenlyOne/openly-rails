# frozen_string_literal: true

module VCS
  # A syncable file
  module Syncable
    extend ActiveSupport::Concern

    included do
      attr_writer :remote
      # Set force sync to execute all jobs synchronously
      attr_accessor :force_sync
    end

    # TODO: Extract to parent class
    # Build the associations for this syncable resource, such as file record
    def build_associations
      self.file_record ||=
        VCS::FileRecord.new(repository_id: branch.repository_id)
    end

    # Fetch the most recent information about this syncable resource from its
    # provider
    def fetch
      self.is_deleted = remote.deleted?
      self.name = remote.name
      self.mime_type = remote.mime_type
      self.content_version = remote.content_version
      self.external_parent_id = remote.parent_id
      thumbnail_from_remote
    end

    # Fetch and save the most recent information about this syncable resource
    def pull(force_sync: false)
      self.force_sync = force_sync
      fetch
      build_associations
      save
    end

    # Fetch and save the children of this syncable resource from its provider
    def pull_children
      self.staged_children = children_from_remote
    end

    # Reset sync state when calling #reload
    def reload
      reset_remote
      super
    end

    def remote
      @remote ||= remote_class.new(remote_file_id)
    end

    # Get version ID of thumbnail
    def thumbnail_version_id
      remote&.thumbnail_version
    end

    private

    # Fetch children from sync adapter and convert to file resources
    def children_from_remote
      remote.children.map do |remote_child|
        staged_child =
          self.class
              .create_with(remote: remote_child)
              .find_or_initialize_by(
                branch: branch,
                remote_file_id: remote_child.id
              )

        # Pull (fetch+save) child if it is a new record
        staged_child.tap { |child| child.pull if child.new_record? }
      end
    end

    # Find an instance of syncable's class from the external parent ID
    # and set instance to parent of current syncable resource
    def external_parent_id=(external_parent_id)
      self.parent =
        branch.staged_files.find_by_remote_file_id(external_parent_id)
    end

    # Reset the file's synchronization adapter
    def reset_remote
      @remote = nil
      @destroy_on_save = nil
    end

    def remote_class
      'Providers::GoogleDrive::FileSync'.constantize
    end

    # Set thumbnail from sync adapter, either by finding an existing thumbnail
    # for this file and its thumbnail version id or by creating a new one and
    # fetching the thumbnail
    def thumbnail_from_remote
      return unless remote.thumbnail?

      self.thumbnail =
        VCS::FileThumbnail
        .create_with(raw_image: proc { remote.thumbnail })
        .find_or_initialize_by_staged_file(self)
    end
  end
end
