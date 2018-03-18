# frozen_string_literal: true

module FileResources
  # A GoogleDrive file resource
  class GoogleDrive < FileResource
    # Associations
    belongs_to :parent, class_name: model_name, optional: true, autosave: false
    has_many :children, class_name: model_name, inverse_of: :parent,
                        foreign_key: :parent_id

    def thumbnail_version_id
      sync_adapter&.thumbnail_version
    end
  end
end
