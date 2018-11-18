# frozen_string_literal: true

require_relative 'attachments_backup_task_helper.rb'

namespace :backup do
  namespace :attachments do
    desc 'Backup: Attachments: Backup the attachments using recursive copy'
    task capture: %i[environment create_directory] do
      unless AttachmentsBackupTaskHelper.perform_backup?
        puts 'Skipping backup of attachments because no attachments exist'
        next
      end

      backup_path = AttachmentsBackupTaskHelper.path_for_new_backup

      puts "Capturing backup of attachments to #{backup_path}..."

      FileUtils.copy_entry(
        AttachmentsBackupTaskHelper.attachments_directory,
        backup_path,
        preserve: true
      )

      backup_size =
        (`du -b -s #{backup_path}`.split.first.to_i / 1.0.megabyte).round(3)

      puts "Done. File size of backup: #{backup_size} MB"
    end
  end
end
