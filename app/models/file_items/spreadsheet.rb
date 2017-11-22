# frozen_string_literal: true

module FileItems
  # FileItems not of type folder (identified by MIME type)
  class Spreadsheet < Base
    # The url template for generating the file's external link
    def self.external_link_template
      'https://docs.google.com/spreadsheets/d/GID'
    end
  end
end
