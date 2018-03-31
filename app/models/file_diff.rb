# frozen_string_literal: true

# Class for handling diffing of File Resources
class FileDiff < ApplicationRecord
  include Diffing

  # Associations
  belongs_to :revision
  belongs_to :file_resource
  belongs_to :current_snapshot, class_name: 'FileResource::Snapshot',
                                optional: true
  belongs_to :previous_snapshot, class_name: 'FileResource::Snapshot',
                                 optional: true

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
end
