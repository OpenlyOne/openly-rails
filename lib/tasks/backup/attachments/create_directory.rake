# frozen_string_literal: true

require_relative 'attachments_backup_task_helper.rb'

namespace :backup do
  desc 'Backup: Database: Create the directory for storing attachment backups'
  namespace :attachments do
    task create_directory: :environment do
      backup_directory = AttachmentsBackupTaskHelper.backup_directory

      puts "Creating #{backup_directory}..."
      FileUtils.mkdir_p(backup_directory)
      puts 'Done'
    end
  end
end
