# frozen_string_literal: true

module Stage
  class FileDiff
    # Class for calculating children (as diffs) of a staged file diff
    # TODO: Needs unit spec
    class Children
      def initialize(project:, parent_id:)
        self.project    = project
        self.parent_id  = parent_id
      end

      # Return the file's children as Stage::FileDiff instances
      def as_diffs
        children = children_of_staged_and_committed_file

        # Convert snapshots into Stage::FileDiff instances
        children =
          children.group_by(&:file_resource_id).values.map do |group|
            children_snapshots_to_diff(group)
          end

        # For each child removed from this parent folder, check if it was moved
        # to another folder (as opposed to having been deleted)
        remove_children_moved_to_another_folder!(children)

        # For each child added to this parent folder, check it it was moved from
        # another folder (as opposed to having been added)
        update_children_moved_into_this_folder!(children)

        children
      end

      private

      attr_accessor :project, :parent_id

      # Return true if the given child_id among the children IDs of the
      # committed file
      def child_of_committed_file?(child_id)
        children_ids_of_committed_file.include?(child_id)
      end

      # Return true if the given child_id among the children IDs of the staged
      # file
      def child_of_staged_file?(child_id)
        children_ids_of_staged_file.include?(child_id)
      end

      # Return the children IDs of the committed file
      def children_ids_of_committed_file
        @children_ids_of_committed_file ||=
          project
          .revisions&.last
          &.committed_file_snapshots&.where(parent_id: parent_id)&.pluck(:id)
          .to_a
      end

      # Return the children IDs of the staged file
      def children_ids_of_staged_file
        @children_ids_of_staged_file ||=
          project
          .non_root_file_snapshots_in_stage
          .where(parent_id: parent_id)
          .pluck(:id)
      end

      # Return the children of both the staged and committed file
      def children_of_staged_and_committed_file
        children_of_staged_and_committed_file =
          children_ids_of_staged_file + children_ids_of_committed_file
        # TODO: Needs to be sorted correctly, folder 1st, then by current or
        #       previous name. The current query won't work for that because
        #       we don't know if the snapshot is staged or committed
        FileResource::Snapshot
          .where(id: children_of_staged_and_committed_file.uniq)
      end

      # Return an instance of Stage::FileDiff for the given array of children
      def children_snapshots_to_diff(children)
        staged_snapshot =
          children.find { |child| child_of_staged_file?(child.id) }
        committed_snapshot =
          children.find { |child| child_of_committed_file?(child.id) }

        Stage::FileDiff.new(project: project,
                            staged_snapshot: staged_snapshot,
                            committed_snapshot: committed_snapshot)
      end

      # Alter the given array of children by removing files that exist
      # elsewhere in the project's stage
      def remove_children_moved_to_another_folder!(children)
        deleted_children = children.select(&:deleted?)

        ids_of_deleted_children_in_stage =
          project
          .non_root_file_snapshots_in_stage
          .where(file_resource: deleted_children.map(&:file_resource_id))
          .pluck(:file_resource_id)

        children.reject! do |child|
          ids_of_deleted_children_in_stage.include?(child.file_resource_id)
        end
      end

      # Alter the given array of children by adding committed snapshots for
      # files that exist elsewhere in the project's last revision
      def update_children_moved_into_this_folder!(children)
        added_children = children.select(&:added?)

        snapshots_of_added_children_in_last_revision =
          project.revisions&.last&.committed_file_snapshots
                 &.where(file_resource: added_children.map(&:file_resource_id))
                 .to_a

        added_children.each do |child|
          child.committed_snapshot =
            snapshots_of_added_children_in_last_revision
            .find { |c| c.file_resource_id == child.file_resource_id }
        end
      end
    end
  end
end
