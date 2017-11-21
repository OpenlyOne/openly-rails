# frozen_string_literal: true

module FileItems
  # FileItems of type folder (identified by MIME type)
  class Folder < Base
    has_many :children, class_name: 'FileItems::Base',
                        foreign_key: 'parent_id',
                        dependent: :destroy,
                        inverse_of: :parent

    # The link to the folder in Google Drive.
    # Return nil if google_drive_id is nil or unset.
    def external_link
      return nil unless google_drive_id
      "https://drive.google.com/drive/folders/#{google_drive_id}"
    end
  end
end
