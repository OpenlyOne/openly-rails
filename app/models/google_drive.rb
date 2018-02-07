# frozen_string_literal: true

# Wrapper class for Google Drive API
# This class is NOT covered by SimpleCov because we're mocking most of it in our
# CI testing.
class GoogleDrive
  class << self
    # Delegations
    delegate :get_file, :get_changes_start_page_token, to: :drive_service

    # Initialize the Google::Apis::DriveV3::DriveService
    def initialize
      @drive_service =
        Providers::GoogleDrive::DriveService.new(
          ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT']
        )
    end

    # Return a hash of the change record's attributes
    def attributes_from_change_record(record)
      attributes = { id: record.file_id }

      # Set parent_id to nil if this file was removed
      attributes[:parent_id] = nil if record.removed

      # If file attribute is present, merge with attributes from file record
      attributes.reverse_merge attributes_from_file_record(record.file)
    end

    # Return a hash of the file record's attributes
    def attributes_from_file_record(record)
      return {} if record.nil?

      record.to_h.tap do |hash|
        hash[:parent_id] = record.trashed? ? nil : record.parents&.first
      end
    end

    # Get file by ID
    def get_file(id_of_file)
      drive_service.get_file(
        id_of_file,
        fields: 'id, name, mimeType, version, modifiedTime'
      )
    end

    # Retrieve the ID from a given link
    # Note: Tested for folders only
    def link_to_id(link_to_file)
      matches = link_to_file.match(%r{\/folders\/?(.+)})
      matches ? matches[1] : nil
    end

    # Lists file changes that have happened since the page token
    # rubocop:disable Metrics/MethodLength
    def list_changes(token, page_size = 100)
      drive_service.list_changes(
        token,
        page_size: page_size,
        fields:
          'nextPageToken, newStartPageToken, '  + # new tokens
          'changes/type, '                      + # type of change, e.g. file
          'changes/file_id, '                   + # the file's id
          'changes/file/mimeType, '             + # the file's mime type
          'changes/file/version, '              + # the file's version
          'changes/file/name, '                 + # the file's name
          'changes/file/modifiedTime, '         + # the file's modification time
          'changes/file/parents, '              + # the file's parents
          'changes/removed, changes/file/trashed' # file deleted?
      )
    end
    # rubocop:enable Metrics/MethodLength

    # Get children (files) of folder with ID id_of_folder
    def list_files_in_folder(id_of_folder)
      drive_service.list_files(
        q: "'#{id_of_folder}' in parents",
        fields:
          'files/id, '           + # the file's id
          'files/version, '      + # the file's version
          'files/mimeType, '     + # the file's mime type
          'files/name, '         + # the file's name
          'files/modifiedTime'     # the file's modification time
      ).files
    end

    private

    # Return the instance of Google::Apis::DriveV3:;DriveService
    # Initialize unless already initialized
    def drive_service
      initialize unless @drive_service
      @drive_service.reload
    end
  end
end
