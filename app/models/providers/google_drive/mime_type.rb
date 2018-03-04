# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Parser for various GoogleDrive-supported mime types
    class MimeType
      MIME_TYPES = {
        document: 'application/vnd.google-apps.document',
        drawing: 'application/vnd.google-apps.drawing',
        folder: 'application/vnd.google-apps.folder',
        form: 'application/vnd.google-apps.form',
        presentation: 'application/vnd.google-apps.presentation',
        spreadsheet: 'application/vnd.google-apps.spreadsheet'
      }.freeze

      class << self
        # Define getters such as .document, .folder, and .spreadsheet
        MIME_TYPES.each do |type, mime_type|
          define_method(type) do
            mime_type
          end
        end

        # Define type checkers such as .document?, .folder?, and .spreadsheet?
        MIME_TYPES.each do |type, mime_type|
          define_method("#{type}?") do |type_to_check|
            type_to_check == mime_type
          end
        end
      end
    end
  end
end
