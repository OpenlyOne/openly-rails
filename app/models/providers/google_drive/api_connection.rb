# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Wrapper class for Google Drive API
    class ApiConnection
      # Return the default connection
      def self.default
        tracking_account
      end

      # Return the connection for the tracking account
      def self.tracking_account
        @tracking_account ||= new(ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'])
      end

      # Create new API connection
      def initialize(google_account)
        @drive_service = DriveService.new(google_account)
      end

      # Create a Google Drive file
      def create_file(name:, parent_id:, mime_type:)
        file = drive_file.new(name: name,
                              parents: [parent_id],
                              mime_type: mime_type)

        drive_service.create_file(file, fields: default_file_fields)
      end

      # Create a Google Drive file in home folder
      def create_file_in_home_folder(name:, mime_type:)
        create_file(name: name, parent_id: 'root', mime_type: mime_type)
      end

      # Delete a file by ID
      def delete_file(id)
        drive_service.delete_file(id)
      end

      # Fetch a file by ID
      def fetch_file(id)
        drive_service.get_file(id, fields: default_file_fields)
      end

      # Retrieve the permission ID for the email account on the file identified
      # by ID
      def file_permission_id_by_email(id, email)
        permission_list = drive_service.list_permissions(
          id, fields: 'permissions/id, permissions/emailAddress'
        )

        permission_list.permissions.find do |permission|
          permission.email_address == email
        end&.id
      end

      # Refresh the authorization token for the API connection
      # This is done automatically, so usually there is no need to manually
      # trigger this
      def refresh_authorization
        drive_service.authorization.refresh!
      end

      # Share the file with the given email account
      def share_file(id, email, role = :reader)
        permission = drive_permission.new(email_address: email,
                                          type: 'user',
                                          role: role.to_s)

        drive_service.create_permission(id, permission,
                                        send_notification_email: 'false')
      end

      # Trash the file identified by ID
      def trash_file(id)
        drive_service.update_file(id,
                                  drive_file.new(trashed: 'true'),
                                  fields: default_file_fields)
      end

      # Stop sharing the file with the given email account
      def unshare_file(id, email)
        permission_id = file_permission_id_by_email(id, email)
        drive_service.delete_permission(id, permission_id)
      end

      # Udpate the contents of the file identified by ID
      def update_file_content(id, content)
        drive_service.update_file(id, upload_source: StringIO.new(content))
      end

      # Update the name of the file identified by ID
      def update_file_name(id, name)
        drive_service.update_file(id,
                                  drive_file.new(name: name),
                                  fields: default_file_fields)
      end

      # Update the parents of the file identified by ID
      def update_file_parents(id, add:, remove:)
        drive_service.update_file(
          id, nil,
          add_parents: add.compact, remove_parents: remove.compact,
          fields: default_file_fields
        )
      end

      private

      attr_reader :drive_service

      # Class for Google Drive files
      def drive_file
        Google::Apis::DriveV3::File
      end

      # Class for Google Drive permissions
      def drive_permission
        Google::Apis::DriveV3::Permission
      end

      # The default fields for file query methods
      def default_file_fields
        %w[id name mimeType parents].join(',')
      end
    end
  end
end
