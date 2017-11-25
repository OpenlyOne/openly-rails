# frozen_string_literal: true

# FileItems are docs, sheets, folders, ... and belong to projects
# (It is named FileItem because File is already in use for FileUtils)
module FileItems
  # STI parent class for files and folders
  class Base < ApplicationRecord
    self.table_name = 'file_items'
    self.inheritance_column = 'mime_type'

    belongs_to :project
    belongs_to :parent, class_name: 'FileItems::Folder', optional: true

    # Define mime types and their corresponding classes
    MIME_TYPES = {
      'application/vnd.google-apps.folder':       'FileItems::Folder',
      'application/vnd.google-apps.document':     'FileItems::Document',
      'application/vnd.google-apps.spreadsheet':  'FileItems::Spreadsheet',
      'application/vnd.google-apps.presentation': 'FileItems::Presentation',
      'application/vnd.google-apps.drawing':      'FileItems::Drawing',
      'application/vnd.google-apps.form':         'FileItems::Form'
    }.freeze

    # Convert between mime types and classes
    class << self
      def find_sti_class(type_name)
        MIME_TYPES[type_name.to_sym]&.constantize || self
      end

      def sti_name
        MIME_TYPES.invert[to_s]
      end
    end

    # The url template for generating the file's external link
    def self.external_link_template
      'https://drive.google.com/file/d/GID'
    end

    # Update all projects affected by the Google::Apis::DriveV3::Change instance
    def self.update_all_projects_from_change(change)
      return unless change.type == 'file'

      projects =
        Project.having_google_drive_files(
          [change.file_id, change&.file&.parents&.first]
        ).order(:id)

      projects.each { |p| update_single_project_from_change(p, change) }
    end

    # Commit the file (set values at last commit)
    def commit!
      update(
        version_at_last_commit: version,
        modified_time_at_last_commit: modified_time,
        parent_id_at_last_commit: parent_id
      )
    end

    # The link to the file in Google Drive.
    # Return nil if google_drive_id is nil or unset.
    def external_link
      return nil unless google_drive_id
      self.class.external_link_template.gsub('GID', google_drive_id)
    end

    # The path to the file item's icon
    def icon
      return nil unless mime_type

      size = '128' # icon size in px
      "https://drive-thirdparty.googleusercontent.com/#{size}/type/#{mime_type}"
    end

    # Marks the file as deleted (or deletes the file if it has been added since
    # the last commit)
    def mark_as_deleted(change)
      return destroy if added_since_last_commit?

      update(
        {}.tap do |hash|
          hash[:version] = change.file.version.to_i if change&.file&.version
          hash[:name] = change.file.name            if change&.file&.name
          hash[:modified_time] = nil
        end
      )
    end

    # Update the file with the new parent and the change
    def update_from_change(new_parent, change)
      # mark file for deletion if parent does not exist
      if new_parent.nil? || change.removed || change.file.trashed
        return mark_as_deleted(change)
      end

      update(
        version: change.file.version.to_i,
        name: change.file.name,
        modified_time: change.file.modified_time,
        parent_id: new_parent.id
      )
    end

    # Whether or not the file has been added since the last commit
    def added_since_last_commit?
      modified_time_at_last_commit.nil?
    end

    # Whether or not the file has been deleted since the last commit
    def deleted_since_last_commit?
      modified_time.nil?
    end

    # Whether or not the file has been modified since the last commit
    def modified_since_last_commit?
      return false if added_since_last_commit? || deleted_since_last_commit?
      modified_time > modified_time_at_last_commit
    end

    # Whether or not the file has been modified since the last commit
    def moved_since_last_commit?
      parent_id_at_last_commit != parent_id
    end

    class << self
      private

      # Update file from change within a single project
      def update_single_project_from_change(project, change)
        file = project.files.find_by(google_drive_id: change.file_id)
        parent =
          project.files.find_by(google_drive_id: change&.file&.parents&.first)

        return file.update_from_change(parent, change) if file.present?
        return parent.create_child_from_change(change) if parent.present?
      end
    end
  end
end
