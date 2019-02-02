# frozen_string_literal: true

module VCS
  # A backupable file
  module Backupable
    extend ActiveSupport::Concern

    included do
      # Callbacks
      after_save :perform_backup, if: :backup_on_save?

      # Delegations
      delegate :backup, to: :current_version, allow_nil: true
    end

    # Has this file resource already been backed up?
    def backed_up?
      backup&.persisted?
    end

    # Should this file resource be backed up on save?
    # No, if folder.
    # No, if deleted.
    # No, if already backed up.
    def backup_on_save?
      !folder? && !deleted? && !backed_up?
    end

    private

    # The action for performing the backup
    def perform_backup
      VCS::Operations::FileBackup.backup(self)
      true
    end
  end
end
