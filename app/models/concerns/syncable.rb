# frozen_string_literal: true

# A syncable FileResource
module Syncable
  extend ActiveSupport::Concern

  # Fetch the most recent information about this syncable resource from its
  # provider
  def fetch
    # Reset the sync state
    reset_sync_state

    # Set attributes
    self.name = sync_adapter.name
    self.mime_type = sync_adapter.mime_type
    self.content_version = sync_adapter.content_version
    self.external_parent_id = sync_adapter.parent_id
    self.is_deleted = sync_adapter.deleted?
  end

  # Fetch and save the most recent information about this syncable resource
  def pull
    fetch
    save
  end

  private

  # Find an instance of syncable's class from the external parent ID
  # and set instance to parent of current syncable resource
  def external_parent_id=(parent_id)
    self.parent = nil
    return if parent_id.nil?
    self.parent = self.class.find_by_external_id(parent_id)
  end

  # Reset the file's synchronization state
  def reset_sync_state
    @sync_adapter = nil
    @destroy_on_save = nil
  end

  def sync_adapter
    @sync_adapter ||= sync_adapter_class.new(external_id)
  end

  def sync_adapter_class
    Object.const_get "#{provider}::FileSync"
  end
end
