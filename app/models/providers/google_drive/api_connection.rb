# frozen_string_literal: true

module Providers
  module GoogleDrive
    # rubocop:disable Metrics/ClassLength

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
        file = GoogleDrive::File.new(name: name,
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

      # Copy a file by ID, optionally providing new name and parent ID
      # TODO: Support duplication without explicit name and parent ID
      def duplicate_file(id, name:, parent_id:)
        duplicate_file!(id, name: name, parent_id: parent_id)
      rescue Google::Apis::ClientError => error
        # only rescue not found errors
        raise unless error.message.starts_with?('cannotCopyFile')
        nil
      end

      # Copy a file by ID, optionally providing new name and parent ID.
      # Raise error if file cannot be copied.
      # TODO: Support duplication without explicit name and parent ID
      def duplicate_file!(id, name:, parent_id:)
        target = GoogleDrive::File.new(name: name, parents: [parent_id])
        drive_service.copy_file(id, target, fields: default_file_fields)
      end

      # Get the file's content by file ID
      def file_content(id)
        content_io = StringIO.new
        drive_service.export_file(id, 'text/plain', download_dest: content_io)
        # Remove BOM
        content_io.string.sub(/^\xEF\xBB\xBF/, '')
      end

      # Find a file by ID. Return nil if file not found
      def find_file(id)
        find_file!(id)
      rescue Google::Apis::ClientError => error
        # only rescue not found errors
        raise unless error.message.starts_with?('notFound')
        nil
      end

      # Find a file by ID. Raise error if file not found
      def find_file!(id)
        drive_service.get_file(id, fields: default_file_fields)
      end

      # Find files by parent
      def find_files_by_parent_id(parent_id)
        drive_service.list_files(
          q:      "'#{parent_id}' in parents",
          fields: prefix_fields('files', default_file_fields)
        ).files
      end

      # Get the most recent revision # of this file
      # Return nil if user does not have necessary permission to fetch revision
      def file_head_revision(id)
        file_head_revision!(id)
      rescue Google::Apis::ClientError => error
        # only rescue errors about revisions not being supported/accessible
        # revisionsNotSupported: raised when querying folders and forms
        # insufficientFilePermissions: raised when we do not have edit access

        # A longstanding #BUG prevents PDF documents from correctly reporting
        # their head revision. Querying head revision for a PDF document raises
        # notFound: Revision not found.
        # See: https://issuetracker.google.com/issues/36759589
        raise unless error.message.start_with?('revisionsNotSupported',
                                               'insufficientFilePermissions',
                                               'notFound: Revision not found')
        1
      end

      # Get the most recent revision # of this file.
      # Raise error if user does not have necessary permission to fetch revision
      def file_head_revision!(id)
        drive_service.get_revision(id, 'head').id.to_i
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

      # Lists file changes that have happened since the page token
      def list_changes(token, page_size = 100)
        drive_service.list_changes(
          token,
          page_size: page_size,
          fields: %w[nextPageToken newStartPageToken changes/file_id].join(',')
        )
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

      def start_token_for_listing_changes
        drive_service.get_changes_start_page_token.start_page_token
      end

      # Get the thumbnail for a file by its url with the given size in pixels
      # Return nil if thumbnail is not found
      def thumbnail(url, size: 350)
        # Set size on thumbnail
        url = add_query_parameters_to_url(url, 'sz' => "s#{size}")

        # Download thumbnail
        execute_api_command(:get, url)
      rescue Google::Apis::ClientError
        nil
      end

      # Trash the file identified by ID
      def trash_file(id)
        drive_service.update_file(id,
                                  GoogleDrive::File.new(trashed: 'true'),
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
                                  GoogleDrive::File.new(name: name),
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

      # Add/Overwrite the given query parameters to the given URL
      def add_query_parameters_to_url(url, parameters)
        uri = URI.parse(url)
        query = Rack::Utils.parse_query(uri.query)
        query.merge!(parameters)
        uri.query = Rack::Utils.build_query(query)
        uri.to_s
      end

      # Class for Google Drive permissions
      def drive_permission
        Google::Apis::DriveV3::Permission
      end

      # The default fields for file query methods
      def default_file_fields
        %w[id name mimeType parents permissions trashed thumbnailLink
           thumbnailVersion].join(',')
      end

      # Run a simple command of the given method against the given URL and pass
      # authorization tokens along
      def execute_api_command(method, url)
        command = Google::Apis::Core::ApiCommand.new(method, url)
        command.options = drive_service.request_options
        command.execute(drive_service.client)
      end

      # Add a prefix to the fields: 'id,name' becomes 'prefix/id,prefix/name'
      def prefix_fields(prefix, fields)
        fields.split(',').map { |field| "#{prefix}/#{field}" }.join(',')
      end
    end

    # rubocop:enable Metrics/ClassLength
  end
end
