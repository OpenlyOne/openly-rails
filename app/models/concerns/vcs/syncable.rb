# frozen_string_literal: true

# A syncable FileResource
module VCS::Syncable
  extend ActiveSupport::Concern

  included do
    attr_writer :sync_adapter
  end

  # Fetch the most recent information about this syncable resource from its
  # provider
  def fetch
    self.is_deleted = sync_adapter.deleted?
    self.name = sync_adapter.name
    self.mime_type = sync_adapter.mime_type
    self.content_version = sync_adapter.content_version
    self.external_parent_id = sync_adapter.parent_id
    thumbnail_from_sync_adapter
  end

  # Fetch and save the most recent information about this syncable resource
  def pull
    fetch
    save
  end

  # Fetch and save the children of this syncable resource from its provider
  def pull_children
    self.staged_children = children_from_sync_adapter
    # children_from_sync_adapter.each do |child|
    #   child.update!(file_record_parent_id: file_record_id)
    # end
    # # TODO: Clear current snapshot of other children
    # children.where.not(id: children_from_sync_adapter.map(&:id)).each(&:pull)
  end

  # Reset sync state when calling #reload
  def reload
    reset_sync_adapter
    super
  end

  def sync_adapter
    @sync_adapter ||= sync_adapter_class.new(external_id)
  end

  # Get version ID of thumbnail
  def thumbnail_version_id
    sync_adapter&.thumbnail_version
  end

  private

  # Fetch children from sync adapter and convert to file resources
  def children_from_sync_adapter
    sync_adapter.children.map do |child_sync_adapter|
      staged_child =
        self
        .class
        .create_with(
          sync_adapter: child_sync_adapter,
          file_record: VCS::FileRecord.new(repository_id: branch.repository_id)
        ).find_or_initialize_by(
          branch_id: branch_id,
          external_id: child_sync_adapter.id
        )

      # Pull (fetch+save) child if it is a new record
      staged_child.tap { |child| child.pull if child.new_record? }
    end
  end

  # Find an instance of syncable's class from the external parent ID
  # and set instance to parent of current syncable resource
  def external_parent_id=(external_parent_id)
    self.parent = branch.staged_files.find_by_external_id(external_parent_id)
  end

  # Reset the file's synchronization adapter
  def reset_sync_adapter
    @sync_adapter = nil
    @destroy_on_save = nil
  end

  def sync_adapter_class
    'Providers::GoogleDrive::FileSync'.constantize
  end

  # Set thumbnail from sync adapter, either by finding an existing thumbnail for
  # this file and its thumbnail version id or by creating a new one and fetching
  # the thumbnail
  def thumbnail_from_sync_adapter
    return unless sync_adapter.thumbnail?

    self.thumbnail =
      VCS::FileThumbnail
      .create_with(raw_image: proc { sync_adapter.thumbnail })
      .find_or_initialize_by_staged_file(self)
  end
end
