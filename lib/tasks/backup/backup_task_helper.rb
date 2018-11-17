# frozen_string_literal: true

# Helper class for backup tasks
class BackupTaskHelper
  def self.toplevel_backup_directory
    Rails.root.join(Settings.backup_storage)
  end
end
