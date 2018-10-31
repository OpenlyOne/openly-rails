# frozen_string_literal: true

module VCS::Operations
  # Calculate and cache file diffs from one commit to another
  class FileDiffsCalculator
    # Initialize a new instance of FileDiffCalculator to calculate file diffs
    # between commit and its parent commit
    # TODO: Rename from commit & parent_commit to new and old
    def initialize(commit:, parent_commit: nil)
      self.commit = commit
      self.parent_commit = parent_commit || commit.parent
    end

    # Persist diffs to database in FileDiffs table
    def cache_diffs!
      VCS::FileDiff.import(diffs, validate: false)
    end

    def file_diffs
      diffs.map { |diff| VCS::FileDiff.new(diff) }
    end

    # Return diffs as attribute hashes
    def diffs
      @diffs ||= calculate_diffs
    end

    private

    attr_accessor :commit, :parent_commit

    # Number of ancestors to load for each diff
    def ancestor_depth
      3
    end

    # Return an array of ancestors names for a given diff, up to default depth
    def ancestors_names_for(diff)
      ancestry_tree.ancestors_names_for(diff['file_record_id'],
                                        depth: ancestor_depth)
    end

    # Return (or load) ancestry tree for diffs
    def ancestry_tree
      @ancestry_tree ||=
        FileAncestryTree.generate(
          commit: commit,
          parent_commit: parent_commit,
          file_record_ids: raw_diffs.map { |diff| diff['file_record_id'] },
          depth: ancestor_depth
        )
    end

    # Calculate diffs by converting raw diffs to attribute hashes and adding
    # ancestor names up to default depth
    def calculate_diffs
      raw_diffs.map do |raw_diff|
        raw_diff_to_diff(raw_diff)
          .merge('first_three_ancestors' => ancestors_names_for(raw_diff))
          .except('file_record_id')
      end
    end

    # Return committed files where snapshot changed from commit parent to
    # commit
    def committed_files_where_snapshot_changed
      VCS::CommittedFile
        .where_snapshot_changed_between_commits(commit, parent_commit&.id)
    end

    # Parse a single raw diff to an attribute diff
    def raw_diff_to_diff(raw_diff)
      raw_diff
        .slice('file_record_id')
        .merge(
          'commit_id' => commit.id,
          'new_snapshot_id' =>
            snapshot_id_from_raw_diff(raw_diff, commit.id),
          'old_snapshot_id' =>
            snapshot_id_from_raw_diff(raw_diff, parent_commit&.id)
        )
    end

    # Return committed files where snapshot changed from commit parent to
    # commit grouped into a single row for every file resource
    def raw_diffs
      @raw_diffs ||=
        VCS::FileDiff
        .select('file_record_id', 'json_agg(subquery) AS snapshots')
        .from(committed_files_where_snapshot_changed)
        .group('file_record_id')
        .reorder('subquery.file_record_id')
        .map(&:attributes)
    end

    # Retrieve the file resource snapshot from the given raw diff and commit
    def snapshot_id_from_raw_diff(raw_diff, commit_id)
      raw_diff['snapshots']
        .find { |snapshots| snapshots['commit_id'] == commit_id }
        &.fetch('file_snapshot_id', nil)
        &.to_i
    end
  end
end
