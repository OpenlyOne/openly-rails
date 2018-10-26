# frozen_string_literal: true

# A snapshotable FileResource
module Snapshotable
  extend ActiveSupport::Concern

  included do
    # Associations
    has_many :snapshots, class_name: 'FileResource::Snapshot'
    belongs_to :current_snapshot, class_name: 'FileResource::Snapshot',
                                  autosave: false,
                                  optional: true,
                                  inverse_of: :file_resource

    # Callbacks
    before_save :clear_snapshot, if:      :deleted?
    after_save  :snapshot!,      unless:  :deleted?

    # Validations
    validate :current_snapshot_must_belong_to_snapshotable,
             if: :current_snapshot
  end

  private

  # Clear the current snapshot association
  def clear_snapshot
    self.current_snapshot = nil
  end

  # Validate that current snapshot is associated with this snapshotable
  def current_snapshot_must_belong_to_snapshotable
    return if current_snapshot.snapshotable_id == id

    errors.add(:current_snapshot, "must belong to this #{model_name}")
  end

  # Capture a snapshot of this snapshotable instance
  def snapshot!
    self.current_snapshot =
      FileResource::Snapshot.for(attributes.merge(file_resource_id: id))
    # find_or_create_current_snapshot_by!(core_snapshot_attributes,
    #                                     supplemental_snapshot_attributes)
    update_column('current_snapshot_id', current_snapshot.id)
  end
end
