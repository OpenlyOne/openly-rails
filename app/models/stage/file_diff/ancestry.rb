# frozen_string_literal: true

module Stage
  class FileDiff
    # Class for retrieving ancestry of a Stage::FileDiff
    class Ancestry
      # Retrieve ancestry for the file resource identified by given ID
      # Return an array of FileResource::Snapshot instances
      # Can return ancestors up to depth x by passing the depth parameter.
      # TODO: Convert this into a single recursive ActiveRecord query
      def self.for(file_resource_snapshot:, project:, depth: -1)
        return [] if depth.zero?

        parent = parent_snapshot_in_stage(file_resource_snapshot, project)
        parent ||=
          parent_snapshot_in_last_revision(file_resource_snapshot, project)

        return [] if parent.nil?

        # call Ancestry again
        [parent] + self.for(file_resource_snapshot: parent,
                            project: project, depth: depth - 1)
      end

      def self.parent_snapshot_in_stage(snapshot, project)
        project
          .non_root_file_snapshots_in_stage
          .find_by(file_resource_id: snapshot.parent_id)
      end

      def self.parent_snapshot_in_last_revision(snapshot, project)
        project
          .revisions
          .last
          &.committed_file_snapshots
          &.find_by(file_resource_id: snapshot.parent_id)
      end
    end
  end
end
