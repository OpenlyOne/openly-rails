# frozen_string_literal: true

require_relative '../backup_task_helper.rb'

# Helper for attachments backup tasks
class AttachmentsBackupTaskHelper < BackupTaskHelper
  # The directory where attachments are stored
  def self.attachments_directory
    Rails.root.join(Settings.attachment_storage)
  end

  # The directory for storing database backups
  def self.backup_directory
    toplevel_backup_directory.join('attachments')
  end

  # Return the path for a new backup
  def self.path_for_new_backup
    backup_directory.join("#{timestamp}_#{Rails.env}_attachments")
  end

  def self.timestamp
    Time.now.strftime('%Y-%m-%d-%Hh-%Mm-%Ss')
  end
end
