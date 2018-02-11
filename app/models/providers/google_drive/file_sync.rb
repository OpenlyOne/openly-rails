# frozen_string_literal: true

module Providers
  module GoogleDrive
    # API Adapter for CRUD operations on Google Drive files
    class FileSync
      attr_reader :id

      def self.create(name:, parent_id:, mime_type:, api_connection: nil)
        api_connection ||= default_api_connection
        file = api_connection.create_file(name: name,
                                          parent_id: parent_id,
                                          mime_type: mime_type)
        new(file.id, file: file, api_connection: api_connection)
      end

      def self.default_api_connection
        ApiConnection.default
      end

      def initialize(id, attributes = {})
        @id             = id
        self.file       = attributes.delete(:file) if attributes.key?(:file)
        @api_connection = attributes.delete(:api_connection)
      end

      def deleted?
        file&.trashed
      end

      def name
        file&.name
      end

      def parent_id
        file&.parents&.first
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

      private

      def api_connection
        @api_connection || self.class.default_api_connection
      end

      # Fetch the file
      def fetch_file
        self.file = api_connection.find_file(id)
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
    end
  end
end
