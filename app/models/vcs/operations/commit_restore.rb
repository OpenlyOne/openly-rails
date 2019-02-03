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
      def restore
        # TODO: Optimize by only doing this for diffs_to_restore that are
        # =>    folders and additions
        until diffs_to_restore.empty?
          diffs_to_restore.each do |diff|
            # check if the diff has a parent
            next unless diff_without_parent?(diff, diffs_to_restore)

            # schedule restoration
            restore_file_from_diff(diff)

            diffs_to_restore.delete(diff)
          end
        end
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

      # Return true if the diff has no parent among all diffs
      # Return false if one of the all_diffs has a file record ID that is the
      # diff's file record parent ID.
      def diff_without_parent?(diff, all_diffs)
        return true if diff.current_version.nil?

        all_diffs.map(&:current_file_id).exclude?(diff.current_parent_id)
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

      # Schedule the file restoration$
      def restore_file_from_diff(diff)
        FileRestoreJob.perform_later(
          reference: target_branch,
          version_id: diff.new_version&.id,
          file_id: diff.file_id
        )
      end
    end
  end
end
