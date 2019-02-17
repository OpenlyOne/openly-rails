# frozen_string_literal: true

module VCS
  module Operations
    # Revert the staged files in the branch to the provided diffs
    class RestoreFilesFromDiffs
      # Attributes
      attr_accessor :diffs_to_restore, :target_branch

      def self.restore(*attributes)
        new(*attributes).restore
      end

      def initialize(file_diffs:, target_branch:)
        self.diffs_to_restore = file_diffs.clone.to_a
        self.target_branch    = target_branch
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

      # Return true if the diff has no parent among all diffs
      # Return false if one of the all_diffs has a file record ID that is the
      # diff's file record parent ID.
      def diff_without_parent?(diff, all_diffs)
        return true if diff.current_version.nil?

        all_diffs.map(&:current_file_id).exclude?(diff.current_parent_id)
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
