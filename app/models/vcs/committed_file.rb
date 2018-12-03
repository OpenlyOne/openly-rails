# frozen_string_literal: true

module VCS
  # Handles associations between commits and file versions
  class CommittedFile < ApplicationRecord
    belongs_to :commit
    belongs_to :version

    validates :version_id,
              uniqueness: {
                scope: %i[commit_id],
                message: 'file version already exists in this revision'
              }

    # Scopes
    # Committed files where version ID changed from commit 1 to commit 2
    scope :where_version_changed_between_commits, lambda { |commit1, commit2|
      joins(:version)
        .select(
          "#{VCS::Version.table_name}.file_id AS file_id",
          :version_id,
          'min(commit_id) AS commit_id'
        )
        .where(commit_id: [commit1, commit2].compact)
        .group("#{VCS::Version.table_name}.file_id", :version_id)
        .having('count(*) = 1')
    }
    scope :distinct_versions_between_commits, lambda { |commit1, commit2|
      joins(:version)
        .select("DISTINCT ON (#{VCS::Version.table_name}.file_id) " \
                "#{VCS::Version.table_name}.file_id")
        .where(commit_id: [commit1, commit2].compact)
        .order("#{VCS::Version.table_name}.file_id", commit_id: :desc)
    }

    # Execute INSERT query based on the SELECT query
    # Order of columns must match order of select statements.
    # For example:
    # CommittedFile.insert_from_select_query(
    #  [:revision_id, :file_resource_id, :file_resource_version_id],
    #  FileResource.select(1, :id, :current_version_id)
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
  end
end
