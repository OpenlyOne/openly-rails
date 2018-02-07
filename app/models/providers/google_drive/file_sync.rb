# frozen_string_literal: true

module Providers
  module GoogleDrive
    # API Adapter for CRUD operations on Google Drive files
    class FileSync
      def self.create(name:, parent_id:, mime_type:, api_connection: nil)
        api_connection ||= default_api_connection
        created_file = api_connection.create_file(name: name,
                                                  parent_id: parent_id,
                                                  mime_type:  mime_type)
        new(file: created_file, api_connection: api_connection)
      end

      def self.default_api_connection
        ApiConnection.default
      end

      def initialize(attributes = {})
        @id             = attributes.delete(:id)
        @file           = attributes.delete(:file)
        @api_connection = attributes.delete(:api_connection)
      end

      def id
        @id || file&.id
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

      def file
        @file ||= api_connection.fetch_file(@id)
      end

      def api_connection
        @api_connection || self.class.default_api_connection
      end
    end
  end
end
