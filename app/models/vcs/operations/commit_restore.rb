# frozen_string_literal: true

module VCS
  module Operations
    # Revert the staged files in the branch back to a particular commit
    class CommitRestore
      # Attributes
      # TODO: Attribute author should be extracted out of this operation. It is
      # =>    not needed. But we need to remove the not null constraint from the
      # =>    database (which we need to do anyway to make it possible for
      # =>    users to delete their accounts).
      attr_accessor :commit, :target_branch, :author

      # Delegations & Alias
      alias commit_to_restore commit

      def self.restore(*attributes)
        new(*attributes).restore
      end

      def initialize(commit:, target_branch:, author:)
        self.commit         = commit
        self.target_branch  = target_branch
        self.author         = author
      end

      # Perform the restoration
      # Delegate to RestoreFilesFromDiffs which makes sure that files are
      # restored in the right order (i.e. parents before children)
      def restore
        RestoreFilesFromDiffs.restore(
          file_diffs: diffs_to_restore,
          target_branch: target_branch
        )
      end

      private

      # Build a VCS::Commit draft that is a snapshot of the files currently
      # in target_branch
      def current_version_of_files
        @current_version_of_files ||=
          VCS::Commit
          .create(branch: target_branch,
                  parent: target_branch.commits.last,
                  author: author)
          .tap(&:commit_all_files_in_branch)
      end

      # Calculate which diffs have to be restored
      def diffs_to_restore
        @diffs_to_restore ||=
          VCS::Operations::FileDiffsCalculator
          .new(
            commit: commit_to_restore,
            parent_commit: current_version_of_files
          ).file_diffs
      end
    end
  end
end
