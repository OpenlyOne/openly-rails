# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Link handler for Google Drive file resources
    class Link
      def self.base_path(subdomain)
        "https://#{subdomain}.google.com"
      end

      def self.for(external_id:, mime_type:)
        type_symbol = MimeType.to_symbol(mime_type)
        safe_send(:"for_#{type_symbol}", external_id) || for_other(external_id)
      end

      def self.for_document(id)
        "#{base_path(:docs)}/document/d/#{id}"
      end

      def self.for_drawing(id)
        "#{base_path(:docs)}/drawings/d/#{id}"
      end

      def self.for_folder(id)
        "#{base_path(:drive)}/drive/folders/#{id}"
      end

      def self.for_form(id)
        "#{base_path(:docs)}/forms/d/#{id}"
      end

      def self.for_presentation(id)
        "#{base_path(:docs)}/presentation/d/#{id}"
      end

      def self.for_spreadsheet(id)
        "#{base_path(:docs)}/spreadsheets/d/#{id}"
      end

      def self.for_other(id)
        "#{base_path(:drive)}/file/d/#{id}"
      end

      # Send the method with arguments if the method exists. Else, return nil.
      def self.safe_send(method, arguments)
        send(method, arguments) if respond_to?(method)
      end
    end
  end
end
