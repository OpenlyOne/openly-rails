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
    before_save :clear_snapshot, if: :deleted?
    with_options unless: :deleted? do
      after_save :snapshot!, if: :saved_changes_to_core_attributes?
      after_save :update_supplemental_snapshot_attributes,
                 if: :saved_changes_to_supplemental_attributes?
    end

    # Validations
    validate :current_snapshot_must_belong_to_snapshotable,
             if: :current_snapshot
  end

  private

  def core_attributes
    attributes.symbolize_keys.slice(*core_attribute_keys)
  end

  def core_attribute_keys
    %i[name external_id content_version mime_type parent_id]
  end

  def core_snapshot_attributes
    core_attributes.merge(file_resource_id: id)
  end

  def find_or_create_current_snapshot_by!(core_attrs, supplemental_attrs)
    self.current_snapshot =
      FileResource::Snapshot
      .create_with(supplemental_attrs)
      .find_or_create_by!(core_attrs)
  end

  # Clear the current snapshot association
  def clear_snapshot
    self.current_snapshot = nil
  end

  # Validate that current snapshot is associated with this snapshotable
  def current_snapshot_must_belong_to_snapshotable
    return if current_snapshot.snapshotable_id == id
    errors.add(:current_snapshot, "must belong to this #{model_name}")
  end

  # Has any of the core attributes been saved changes to?
  def saved_changes_to_core_attributes?
    saved_changes.symbolize_keys.slice(*core_attribute_keys).any?
  end

  # Has any of the supplemental attributes been saved changes to?
  def saved_changes_to_supplemental_attributes?
    saved_changes.symbolize_keys.slice(*supplemental_attribute_keys).any?
  end

  # Capture a snapshot of this snapshotable instance
  def snapshot!
    find_or_create_current_snapshot_by!(core_snapshot_attributes,
                                        supplemental_snapshot_attributes)
    update_column('current_snapshot_id', current_snapshot.id)
  end

  def supplemental_attributes
    attributes.symbolize_keys.slice(*supplemental_attribute_keys)
  end

  def supplemental_attributes_of_current_snapshot
    current_snapshot
      &.attributes
      &.symbolize_keys
      &.slice(*supplemental_attribute_keys)
  end

  def supplemental_attribute_keys
    %i[thumbnail_id]
  end

  def supplemental_snapshot_attributes
    supplemental_attributes
  end

  def update_supplemental_snapshot_attributes
    # Return all supplemental attribute key-value pairs that are not
    # supplemental attributes of current snapshot
    # h1: {thumbnail: '1', attribute_a: 'abc'}
    # h2: {thumbnail: '2'}
    # --> {thumbnail: '1', attribute_a: 'abc'}
    # See: https://stackoverflow.com/a/24642938/6451879
    attributes_to_update =
      (supplemental_attributes.to_a -
       supplemental_attributes_of_current_snapshot.to_a).to_h

    # If there are no attributes to update, exit
    return if attributes_to_update.none?

    # Update current snapshot, bypassing callbacks
    current_snapshot.update_columns(attributes_to_update)
  end
end
