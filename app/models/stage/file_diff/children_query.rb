# frozen_string_literal: true

module Stage
  class FileDiff
    # Class for querying children (as diffs) of a staged file diff
    class ChildrenQuery
      include Enumerable

      def initialize(project:, parent_id:)
        self.project    = project
        self.parent_id  = parent_id
      end

      # Enumerate on children
      def each(&block)
        children.each(&block)
      end

      private

      attr_accessor :project, :parent_id

      # The query for children as file diffs, with current and previous
      # snapshot, and sorted by name with folders first
      def children
        @children ||=
          ::FileDiff
          .from("(#{join_staged_and_committed_snapshots.to_sql}) file_diffs")
          .includes(:current_snapshot, :previous_snapshot)
          .order_by_name_with_folders_first
      end

      # Committed snapshots that need to be fetched are a combination of:
      # 1) snapshots where the most recent version of file is a child of parent
      # 2) snapshots that were child of parent but have now been deleted
      def committed_snapshots
        committed_snapshots_that_are_currently_in_parent.or(
          committed_snapshots_that_were_in_parent_and_are_now_deleted
        )
      end

      # Return all snapshots of last revision where the current snapshot of the
      # committed snapshot's file resource is in the parent
      def committed_snapshots_that_are_currently_in_parent
        FileResource::Snapshot
          .of_revision(last_revision)
          .where_current_snapshot_parent(parent_id)
      end

      # Return all snapshots of last revision that belonged to parent but are
      # now deleted
      def committed_snapshots_that_were_in_parent_and_are_now_deleted
        FileResource::Snapshot
          .of_revision(last_revision)
          .where(parent_id: parent_id)
          .where_current_snapshot_is_nil
      end

      # Join query of staged and committed snapshots
      def join_staged_and_committed_snapshots
        ::FileDiff.select('COALESCE(staged_snapshots.file_resource_id, ' \
                                   'committed_snapshots.file_resource_id) '\
                          'AS file_resource_id, '\
                          'staged_snapshots.id AS current_snapshot_id, '\
                          'committed_snapshots.id AS previous_snapshot_id')
                  .from("(#{staged_snapshots.to_sql}) staged_snapshots")
                  .joins("FULL JOIN (#{committed_snapshots.to_sql}) "\
                         'committed_snapshots '\
                         'ON staged_snapshots.file_resource_id = '\
                            'committed_snapshots.file_resource_id')
      end

      # The last revision in the project
      def last_revision
        @last_committed_snapshot_for ||= project.revisions.last
      end

      # Return all snapshots staged in project that belong to parent
      def staged_snapshots
        project.non_root_file_snapshots_in_stage.where(parent_id: parent_id)
      end
    end
  end
end
