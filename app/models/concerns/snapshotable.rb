# frozen_string_literal: true

# A snapshotable FileResource
module Snapshotable
  extend ActiveSupport::Concern

  included do
    has_many :snapshots, class_name: 'FileResource::Snapshot'
    belongs_to :current_snapshot, class_name: 'FileResource::Snapshot',
                                  autosave: false,
                                  optional: true,
                                  inverse_of: :file_resource

    before_save :clear_snapshot, if: :deleted?
    after_save :snapshot!, if: :saved_changes_to_metadata?, unless: :deleted?
  end

  private

  def metadata
    attributes.symbolize_keys.slice(*metadata_keys)
  end

  def metadata_keys
    %i[name external_id content_version mime_type parent_id]
  end

  def find_or_create_current_snapshot_by!(attributes)
    self.current_snapshot =
      FileResource::Snapshot.find_or_create_by!(attributes)
  end

  # Clear the current snapshot association
  def clear_snapshot
    self.current_snapshot = nil
  end

  # Has any of the metadata been saved changes to?
  def saved_changes_to_metadata?
    saved_changes.symbolize_keys.slice(*metadata_keys).any?
  end

  # Capture a snapshot of this snapshotable instance
  def snapshot!
    find_or_create_current_snapshot_by!(snapshot_attributes)
    update_column('current_snapshot_id', current_snapshot.id)
  end

  def snapshot_attributes
    metadata.merge(file_resource_id: id)
  end
end
