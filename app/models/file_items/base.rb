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

    # Whether or not the file has been modified
    def modified?
      version > version_at_last_commit
    end
  end
end
