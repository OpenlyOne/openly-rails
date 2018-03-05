# frozen_string_literal: true

module Stage
  # Class for handling diffing of staged File Resources to those of last
  # revision
  class FileDiff
    include Diffing

    attr_accessor :committed_snapshot, :file_resource_id, :project,
                  :staged_snapshot

    # Initialize a new FileDiff instance for the file resource identified by
    # external id. Gets staged snapshot from project stage and committed
    # snapshot from the project's last revision.
    # Raise ActiveRecord::RecordNotFound if file resource does not exist at all
    # Raise ActiveRecord::RecordNotFound if file is found neither in stage nor
    # in last revision.
    def self.find_by!(external_id:, project:)
      file = FileResource.find_by!(external_id: external_id)

      staged = staged_snapshot_for(file, project)
      committed = last_committed_snapshot_for(file, project)

      # Raise error if both staged and committed are nil
      raise ActiveRecord::RecordNotFound if staged.nil? && committed.nil?

      new(project: project,
          staged_snapshot: staged, committed_snapshot: committed)
    end

    # Get the current snapshot for the given file resource staged in project
    def self.staged_snapshot_for(file_resource, project)
      project
        .non_root_file_snapshots_in_stage
        .find_by(file_resource: file_resource)
    end

    # Get the committed snapshot for the given file resource from the project's
    # last revision
    def self.last_committed_snapshot_for(file_resource, project)
      project
        .revisions
        &.last
        &.committed_file_snapshots
        &.find_by(file_resource: file_resource)
    end

    def initialize(attributes = {})
      self.project            = attributes.delete(:project)
      self.staged_snapshot    = attributes.delete(:staged_snapshot)
      self.committed_snapshot = attributes.delete(:committed_snapshot)
      self.file_resource_id   = attributes.delete(:file_resource_id)

      # Set file resource id if not yet set
      set_file_resource_id_from_snapshots unless file_resource_id.present?
    end

    # Return the ancestors (as snapshots) of this diff
    def ancestors_in_project
      return [] if current_or_previous_snapshot.nil?

      Ancestry.for(file_resource_snapshot: current_or_previous_snapshot,
                   project: project)
    end

    # Return this file's children as an array of Stage::FileDiff instances
    def children_as_diffs
      Children.new(project: project, parent_id: file_resource_id).as_diffs
    end

    # Return the first three ancestors (names only) of this diff
    def first_three_ancestors
      return [] if current_or_previous_snapshot.nil?

      Ancestry
        .for(file_resource_snapshot: current_or_previous_snapshot,
             project: project, depth: 3)
        .map(&:name)
    end

    # The ID of the current or previous snapshot
    def snapshot_id
      current_or_previous_snapshot_id
    end

    private

    def current_snapshot
      staged_snapshot
    end

    def current_snapshot_id
      staged_snapshot&.id
    end

    def previous_snapshot
      committed_snapshot
    end

    def previous_snapshot_id
      committed_snapshot&.id
    end

    def set_file_resource_id_from_snapshots
      self.file_resource_id =
        (staged_snapshot || committed_snapshot)&.file_resource_id
    end
  end
end
