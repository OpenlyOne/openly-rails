# frozen_string_literal: true

module Providers
  module GoogleDrive
    # API Adapter for CRUD operations on Google Drive files
    class FileSync
      def self.create(name, parent_id, mime_type)
        created_file = Api.create_file(name, parent_id, mime_type)
        new(file: created_file)
      end

      def initialize(attributes = {})
        @id       = attributes.delete(:id)
        @file     = attributes.delete(:file)
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
        @file = Api.update_file_parents(id, add: [to], remove: [from])
      end

      # Rename the file
      def rename(name)
        @file = Api.update_file_name(id, name)
      end

      private

      def file
        @file ||= Api.fetch_file(@id)
      end
    end
  end
end
