# frozen_string_literal: true

module FileItems
  # FileItems of type folder (identified by MIME type)
  class Folder < Base
    has_many :children, class_name: 'FileItems::Base',
                        foreign_key: 'parent_id',
                        dependent: :destroy,
                        inverse_of: :parent

    # The url template for generating the file's external link
    def self.external_link_template
      'https://drive.google.com/drive/folders/GID'
    end

    # The path to the file item's icon
    # We customize the folder icon because Google's default folder icon looks
    # sort of bland
    def icon
      'files/folder.png'
    end
  end
end
