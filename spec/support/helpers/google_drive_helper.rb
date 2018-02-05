# frozen_string_literal: true

# GoogleDrive helper methods
# TODO: Rename to GoogleDriveHelper
module GoogleDriveTestHelper
  # creates a test folder
  def create_google_drive_test_folder(api_connection = nil)
    api_connection ||= default_api_connection
    @google_drive_test_folder =
      api_connection.create_file_in_home_folder(
        name: "Test @ #{Time.zone.now}",
        mime_type: Providers::GoogleDrive::MimeType.folder
      )
  end

  # deletes the test folder
  def delete_google_drive_test_folder(api_connection = nil)
    return unless @google_drive_test_folder

    api_connection ||= default_api_connection
    api_connection.delete_file(google_drive_test_folder_id)
    @google_drive_test_folder = nil
  end

  # gets the ID of the test folder
  def google_drive_test_folder_id
    @google_drive_test_folder.id
  end

  # Create a Google Drive file
  # Optionally fills name and mime type with fake values
  def create_google_drive_file(args)
    args.reverse_merge!(
      name: Faker::File.file_name('', nil, nil, ''),
      mime_type: Providers::GoogleDrive::MimeType.document
    )

    Providers::GoogleDrive::FileSync.create(args)
  end

  private

  def default_api_connection
    Providers::GoogleDrive::ApiConnection.default
  end
end
