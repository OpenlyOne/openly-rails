# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Parser for various GoogleDrive-supported mime types
    class MimeType
      MIME_TYPES = {
        document: 'application/vnd.google-apps.document',
        folder: 'application/vnd.google-apps.folder',
        spreadsheet: 'application/vnd.google-apps.spreadsheet'
      }.freeze

      class << self
        # Define getters such as .document, .folder, and .spreadsheet
        MIME_TYPES.each do |type, mime_type|
          define_method(type) do
            mime_type
          end
        end
      end
    end
  end
end
