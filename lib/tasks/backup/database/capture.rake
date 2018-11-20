# frozen_string_literal: true

require 'open3'
require_relative 'database_backup_task_helper.rb'

namespace :backup do
  desc 'Backup: Database: Backup the database using pg_dump'
  namespace :database do
    task capture: %i[environment create_directory] do
      backup_path = DatabaseBackupTaskHelper.path_for_new_backup

      puts "Capturing backup of #{DatabaseBackupTaskHelper.database_name} " \
           "to #{backup_path}..."

      _stdout, stderr, status = Open3.capture3(
        DatabaseBackupTaskHelper.authentication_environment_variables,
        'pg_dump',
        '--format=custom',
        '--verbose',
        '--no-owner',
        '--oids',
        '--dbname',
        DatabaseBackupTaskHelper.database_name,
        '--file',
        backup_path.to_s
      )

      # Print stderr because stdout is empty on success
      puts stderr
      raise("Error encountered: #{status}") unless status.success?

      backup_size = (File.size(backup_path) / 1.0.megabyte).round(3)

      puts "Done. File size of backup: #{backup_size} MB"
    end
  end
end
