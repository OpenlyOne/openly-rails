# frozen_string_literal: true

require_relative 'database_backup_task_helper.rb'

namespace :backup do
  desc 'Backup: Database: Create the directory for storing database backups'
  namespace :database do
    task create_directory: :environment do
      backup_directory = DatabaseBackupTaskHelper.backup_directory

      puts "Creating #{backup_directory}..."
      FileUtils.mkdir_p(backup_directory)
      puts 'Done'
    end
  end
end
