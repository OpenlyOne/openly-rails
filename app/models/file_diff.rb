# frozen_string_literal: true

# Class for handling diffing of File Resources
class FileDiff < ApplicationRecord
  include Diffing

  # Associations
  belongs_to :revision, inverse_of: :file_diffs
  belongs_to :file_resource
  belongs_to :current_snapshot, -> { with_provider_id },
             class_name: 'FileResource::Snapshot',
             optional: true
  belongs_to :previous_snapshot, -> { with_provider_id },
             class_name: 'FileResource::Snapshot',
             optional: true

  # Delegations
  delegate :committed_files, to: :revision

  # Join snapshot on the current snapshot or previous snapshot ID
  scope :joins_current_or_previous_snapshot, lambda {
    joins(
      'INNER JOIN file_resource_snapshots current_or_previous_snapshot '\
      'ON COALESCE(file_diffs.current_snapshot_id, '\
                  'file_diffs.previous_snapshot_id) '\
      '= current_or_previous_snapshot.id'
    )
  }

  # Order file diffs by
  # 1) directory first and
  # 2) file name in ascending alphabetical order, case insensitive
  scope :order_by_name_with_folders_first, lambda {
    joins_current_or_previous_snapshot.merge(
      FileResource.order_by_name_with_folders_first(
        table: 'current_or_previous_snapshot'
      )
    )
  }

  # Validations
  # Either current or previous snapshot must be present
  validates :current_snapshot_id, presence: true, unless: :previous_snapshot_id
  validates :previous_snapshot_id, presence: true, unless: :current_snapshot_id

  # Apply selected changes to this file diff
  def apply_selected_changes
    # Skip if all changes are selected
    return if changes.all?(&:selected?)

    # apply selected changes
    changes.each(&:apply)

    # persist changes to committed files
    persist_file_to_committed_files
  end

  private

  # Persist current file resource snapshot to the revision's committed files
  def persist_file_to_committed_files
    if current_snapshot_id.present? && current_snapshot_id_was.present?
      update_file_in_committed_files    # Rollback file update

    elsif current_snapshot_id_was.present?
      delete_file_from_committed_files  # Rollback file addition

    elsif current_snapshot_id.present?
      add_file_to_committed_files       # Rollback file deletion
    end
  end

  # Rollback file addition: Delete the file resource from the committed files
  def delete_file_from_committed_files
    committed_files.find_by_file_resource_id(file_resource_id).destroy
  end

  # Rollback file deletion: Add the file resource to the committed files
  def add_file_to_committed_files
    committed_files.create(file_resource_id: file_resource_id,
                           file_resource_snapshot_id: current_snapshot.id)
  end

  # Rollback file update: Update the file resource in the committed files
  def update_file_in_committed_files
    committed_files
      .find_by_file_resource_id(file_resource_id)
      .update!(file_resource_snapshot: current_snapshot.snapshot!)
  end
end
