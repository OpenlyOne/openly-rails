# frozen_string_literal: true

# A syncable FileResource
module Syncable
  extend ActiveSupport::Concern

  # Allow initialization of sync adapter
  def initialize(attributes = {})
    self.sync_adapter = attributes.delete(:sync_adapter)
    super
  end

  # Fetch the most recent information about this syncable resource from its
  # provider
  def fetch
    self.name = sync_adapter.name
    self.mime_type = sync_adapter.mime_type
    self.content_version = sync_adapter.content_version
    self.external_parent_id = sync_adapter.parent_id
    thumbnail_from_sync_adapter
    self.is_deleted = sync_adapter.deleted?
  end

  # Fetch and save the most recent information about this syncable resource
  def pull
    fetch
    save
  end

  # Fetch and save the children of this syncable resource from its provider
  def pull_children
    self.children = children_from_sync_adapter
  end

  # Reset sync state when calling #reload
  def reload
    reset_sync_adapter
    super
  end

  private

  attr_writer :sync_adapter

  # Fetch children from sync adapter and convert to file resources
  def children_from_sync_adapter
    sync_adapter.children.map do |child_sync_adapter|
      find_by_or_initialize_and_pull(child_sync_adapter,
                                     external_id: child_sync_adapter.id)
    end
  end

  # Find or initialize the file resource by attributes.
  # If new record, initialize with sync adapter and pull
  def find_by_or_initialize_and_pull(sync_adapter, attributes)
    self.class.find_by(attributes) ||
      self.class.new(attributes.merge(sync_adapter: sync_adapter)).tap(&:pull)
  end

  # Find an instance of syncable's class from the external parent ID
  # and set instance to parent of current syncable resource
  def external_parent_id=(parent_id)
    self.parent = nil
    return if parent_id.nil?
    self.parent = self.class.find_by_external_id(parent_id)
  end

  # Reset the file's synchronization adapter
  def reset_sync_adapter
    @sync_adapter = nil
    @destroy_on_save = nil
  end

  def sync_adapter
    @sync_adapter ||= sync_adapter_class.new(external_id)
  end

  def sync_adapter_class
    Object.const_get "#{provider}::FileSync"
  end

  # Set thumbnail from sync adapter, either by finding an existing thumbnail for
  # this file and its thumbnail version id or by creating a new one and fetching
  # the thumbnail
  def thumbnail_from_sync_adapter
    return unless sync_adapter.thumbnail?
    self.thumbnail =
      FileResource::Thumbnail
      .create_with(raw_image: proc { sync_adapter.thumbnail })
      .find_or_initialize_by_file_resource(self)
  end
end
