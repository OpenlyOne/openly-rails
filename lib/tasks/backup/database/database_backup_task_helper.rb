# frozen_string_literal: true

require_relative '../backup_task_helper.rb'

# Helper for database backup tasks
class DatabaseBackupTaskHelper < BackupTaskHelper
  class << self
    delegate :connection_config, to: 'ActiveRecord::Base'
    alias config connection_config
  end

  # The directory for storing database backups
  def self.backup_directory
    toplevel_backup_directory.join('database')
  end

  # Name of the database to backup
  def self.database_name
    config.fetch(:database)
  end

  # Name of the database user
  def self.username
    config.fetch(:username, nil)
  end

  # Password of the database user
  def self.password
    config.fetch(:password, nil)
  end

  def self.authentication_environment_variables
    {}.tap do |hash|
      hash['PGUSER']      = username if username.present?
      hash['PGPASSWORD']  = password if password.present?
    end
  end

  # Return the path for a new backup
  def self.path_for_new_backup
    backup_directory.join("#{timestamp}_#{database_name}.dump")
  end

  def self.timestamp
    Time.now.strftime('%Y-%m-%d-%Hh-%Mm-%Ss')
  end
end
