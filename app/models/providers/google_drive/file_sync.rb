# frozen_string_literal: true

module Providers
  module GoogleDrive
    # API Adapter for CRUD operations on Google Drive files
    # rubocop:disable Metrics/ClassLength
    class FileSync
      attr_reader :id

      def self.create(name:, parent_id:, mime_type:, api_connection: nil)
        api_connection ||= default_api_connection
        file = api_connection.create_file(name: name,
                                          parent_id: parent_id,
                                          mime_type: mime_type)
        new(file.id, file: file, api_connection: api_connection)
      end

      def self.upload(name:, parent_id:, mime_type:, file:, api_connection: nil)
        api_connection ||= default_api_connection
        remote_file = api_connection.upload_file(name: name,
                                                 parent_id: parent_id,
                                                 file: file,
                                                 mime_type: mime_type)
        new(remote_file.id, file: remote_file, api_connection: api_connection)
      end

      def self.default_api_connection
        ApiConnection.default
      end

      def initialize(id, attributes = {})
        @id             = id
        self.file       = attributes.delete(:file) if attributes.key?(:file)
        @api_connection = attributes.delete(:api_connection)
      end

      def children
        @children ||= fetch_children_as_file_syncs
      end

      # TODO: Add support for getting content of different file formats
      def content
        return nil if deleted?

        @content ||= fetch_content
      end

      def content_version
        return nil if deleted?

        @content_version ||= fetch_content_version
      end

      # Remove the file
      def delete
        @file = api_connection.delete_file(id)
      end

      def deleted?
        file&.trashed
      end

      # Download the file to the given destination
      def download
        type = MimeType.new(mime_type)
        if type.exportable?
          api_connection.export_file(id, format: type.export_as)
        else
          api_connection.download_file(id)
        end
      end

      # TODO: support duplication without explicit name and parent_id
      def duplicate(name:, parent_id:)
        copy =
          api_connection.duplicate_file(id, name: name, parent_id: parent_id)
        self.class.new(copy.id, file: copy)
      end

      def mime_type
        file&.mime_type
      end

      def name
        file&.name
      end

      def parent_id
        file&.parents&.first
      end

      def permissions
        file&.permissions
      end

      # Relocate the file to a new parent, optionally removing old parent
      def relocate(to:, from:)
        @file =
          api_connection.update_file_parents(id, add: [to], remove: [from])
      end

      # Rename the file
      def rename(name)
        @file = api_connection.update_file_name(id, name)
      end

      # Return the file's thumbnail
      def thumbnail
        return nil unless thumbnail?

        @thumbnail ||= fetch_thumbnail
      end

      # Return the version of the file's thumbnail
      def thumbnail_version
        file&.thumbnail_version
      end

      # Return true if the file has a thumbnail
      def thumbnail?
        return false if deleted?

        thumbnail_link.present?
      end

      # Update file contents
      def update_content(content)
        @file = api_connection.update_file_content(id, content)
      end

      private

      def api_connection
        @api_connection || self.class.default_api_connection
      end

      # Fetch the file's subfiles
      def fetch_children
        api_connection.find_files_by_parent_id(id)
      end

      # Fetch the file's subfiles and convert to FileSync instances
      def fetch_children_as_file_syncs
        fetch_children.map do |file|
          self.class.new(file.id, file: file)
        end
      end

      # Fetch the content
      def fetch_content
        api_connection.file_content(id)
      end

      # Fetch the content version
      def fetch_content_version
        api_connection.file_head_revision(id)
      end

      # Fetch the file
      def fetch_file
        self.file = api_connection.find_file(id)
      end

      # Fetch the thumbnail
      def fetch_thumbnail
        api_connection.thumbnail(thumbnail_link)
      end

      # Return file, or fetch file if not yet initialized
      def file
        fetch_file unless @file
        @file
      end

      # Set @file instance variable to file or to an empty file instance if file
      # has deleted
      def file=(file)
        @file =
          if GoogleDrive::File.deleted?(file)
            GoogleDrive::File.new(trashed: true)
          else
            file
          end
      end

      # The link to the file's thumbnail
      def thumbnail_link
        file&.thumbnail_link
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
