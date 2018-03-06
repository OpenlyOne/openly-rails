# frozen_string_literal: true

module Providers
  module GoogleDrive
    # Icon handler for Google Drive file resources
    class Icon
      SUPPORTED =
        %i[document drawing folder form presentation spreadsheet].freeze

      def self.for(mime_type:)
        mime_type_symbol = MimeType.to_symbol(mime_type)

        return default(mime_type) unless SUPPORTED.include?(mime_type_symbol)

        "files/#{mime_type_symbol}.png"
      end

      def self.default(mime_type)
        "https://drive-thirdparty.googleusercontent.com/128/type/#{mime_type}"
      end
    end
  end
end
