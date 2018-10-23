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

  # Scopes
  # Committed files where snapshot ID changed from revision 1 to revision 2
  scope :where_snapshot_changed_between_revisions, lambda { |rev1, rev2|
    select(:file_resource_id,
           :file_resource_snapshot_id,
           'min(revision_id) AS revision_id')
      .where(revision_id: [rev1, rev2].compact)
      .group(:file_resource_id, :file_resource_snapshot_id)
      .having('count(*) = 1')
  }
  scope :distinct_file_resources_between_revisions, lambda { |rev1, rev2|
    select('DISTINCT ON (committed_files.file_resource_id) ' \
           'committed_files.file_resource_id')
      .where(revision_id: [rev1, rev2].compact)
      .order(:file_resource_id, revision_id: :desc)
  }

  # Execute INSERT query based on the SELECT query
  # Order of columns must match order of select statements.
  # For example:
  # CommittedFile.insert_from_select_query(
  #  [:revision_id, :file_resource_id, :file_resource_snapshot_id],
  #  FileResource.select(1, :id, :current_snapshot_id)
  # )
  # Timestamps (created_at and updated_at) are automatically added.
  def self.insert_from_select_query(columns, select_query)
    columns.push(:created_at, :updated_at)

    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{table_name} (#{columns.join(', ')})\n" +
      select_query.select('NOW() AS created_at', 'NOW() AS updated_at').to_sql
    )
  end

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
    return if file_resource_snapshot&.file_resource_id == file_resource_id
    errors.add(:file_resource_snapshot, 'does not belong to file resource')
  end
end
