# frozen_string_literal: true

class Revision
  # Calculate and cache file diffs from one revision to another
  class FileDiffsCalculator
    # Initialize a new instance of FileDiffCalculator to calculate file diffs
    # between revision and its parent revision
    def initialize(revision:)
      self.revision = revision
    end

    # Persist diffs to database in FileDiffs table
    def cache_diffs!
      FileDiff.import(diffs, validate: false)
    end

    # Return diffs as attribute hashes
    def diffs
      @diffs ||= calculate_diffs
    end

    private

    attr_accessor :revision

    # Calculate diffs by converting raw diffs to attribute hashes and adding
    # ancestor names up to default depth
    def calculate_diffs
      raw_diffs.map do |raw_diff|
        raw_diff_to_diff(raw_diff)
          .merge('first_three_ancestors' => [])
      end
    end

    # Return committed files where snapshot changed from revision parent to
    # revision
    def committed_files_where_snapshot_changed
      CommittedFile
        .where_snapshot_changed_between_revisions(revision, revision.parent_id)
    end

    # Parse a single raw diff to an attribute diff
    def raw_diff_to_diff(raw_diff)
      raw_diff
        .slice('file_resource_id')
        .merge(
          'revision_id' => revision.id,
          'current_snapshot_id' =>
            snapshot_id_from_raw_diff(raw_diff, revision.id),
          'previous_snapshot_id' =>
            snapshot_id_from_raw_diff(raw_diff, revision.parent_id)
        )
    end

    # Return committed files where snapshot changed from revision parent to
    # revision grouped into a single row for every file resource
    def raw_diffs
      @raw_diffs ||=
        FileDiff.select(:file_resource_id, 'json_agg(subquery) AS snapshots')
                .from(committed_files_where_snapshot_changed)
                .group(:file_resource_id)
                .reorder('subquery.file_resource_id')
                .map(&:attributes)
    end

    # Retrieve the file resource snapshot from the given raw diff and revision
    def snapshot_id_from_raw_diff(raw_diff, revision_id)
      raw_diff['snapshots']
        .find { |snapshots| snapshots['revision_id'] == revision_id }
        &.fetch('file_resource_snapshot_id', nil)
        &.to_i
    end
  end
end
