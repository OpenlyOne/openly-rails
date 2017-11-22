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
      'application/vnd.google-apps.folder': 'FileItems::Folder'
    }.freeze

    # Convert between mime types and classes
    class << self
      def find_sti_class(type_name)
        MIME_TYPES[type_name.to_sym]&.constantize || FileItems::File
      end

      def sti_name
        MIME_TYPES.invert[to_s]
      end
    end

    # The link to the file in Google Drive.
    # Return nil if google_drive_id is nil or unset.
    def external_link
      return nil unless google_drive_id
      "https://drive.google.com/file/d/#{google_drive_id}"
    end

    # The path to the file item's icon
    def icon
      return nil unless mime_type

      size = '128' # icon size in px
      "https://drive-thirdparty.googleusercontent.com/#{size}/type/#{mime_type}"
    end
  end
end
