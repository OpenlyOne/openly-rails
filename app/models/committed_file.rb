# frozen_string_literal: true

# Handles associations between revisions, file resources, and file resource
# snapshots (committed files)
class CommittedFile < ApplicationRecord
  belongs_to :revision, autosave: false
  belongs_to :file_resource, autosave: false
  belongs_to :file_resource_snapshot, class_name: 'FileResource::Snapshot',
                                      autosave: false

  validates :file_resource_id,
            uniqueness: {
              scope: %i[revision_id],
              message: 'already exists in this revision'
            }
  validate :file_resource_snapshot_belongs_to_file_resource

  # Mark record as read only when revision is published
  def readonly?
    revision_published?
  end

  # Has the revision been published?
  def revision_published?
    revision&.published?
  end

  private

  def file_resource_snapshot_belongs_to_file_resource
    return if file_resource_snapshot.file_resource_id == file_resource_id
    errors.add(:file_resource_snapshot, 'does not belong to file resource')
  end
end
