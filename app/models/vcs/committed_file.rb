# frozen_string_literal: true

module VCS
  # Handles associations between commits and file snapshots
  class CommittedFile < ApplicationRecord
    belongs_to :commit
    belongs_to :file_snapshot

    validates :file_snapshot_id,
              uniqueness: {
                scope: %i[commit_id],
                message: 'file snapshot already exists in this revision'
              }

    # Scopes
    # Committed files where snapshot ID changed from commit 1 to commit 2
    scope :where_snapshot_changed_between_commits, lambda { |commit1, commit2|
      joins(:file_snapshot)
        .select(
          "#{VCS::FileSnapshot.table_name}.file_id AS file_id",
          :file_snapshot_id,
          'min(commit_id) AS commit_id'
        )
        .where(commit_id: [commit1, commit2].compact)
        .group("#{FileSnapshot.table_name}.file_id", :file_snapshot_id)
        .having('count(*) = 1')
    }
    scope :distinct_file_resources_between_commits, lambda { |commit1, commit2|
      joins(:file_snapshot)
        .select("DISTINCT ON (#{FileSnapshot.table_name}.file_id) " \
                "#{FileSnapshot.table_name}.file_id")
        .where(commit_id: [commit1, commit2].compact)
        .order("#{FileSnapshot.table_name}.file_id", commit_id: :desc)
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

    # Mark record as read only when commit is published
    def readonly?
      commit_published?
    end

    # Has the commit been published?
    def commit_published?
      commit&.published?
    end

    private

    def file_resource_snapshot_belongs_to_file_resource
      return if file_resource_snapshot&.file_resource_id == file_resource_id

      errors.add(:file_resource_snapshot, 'does not belong to file resource')
    end
  end
end
