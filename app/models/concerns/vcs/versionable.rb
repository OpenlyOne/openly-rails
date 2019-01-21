# frozen_string_literal: true

module VCS
  # A versionable file
  module Versionable
    extend ActiveSupport::Concern

    included do
      # Associations
      belongs_to :current_version, class_name: 'VCS::Version',
                                   autosave: false,
                                   optional: true

      # Callbacks
      before_save :clear_version, if:      :deleted?
      after_save  :version!,      unless:  :deleted?

      # Validations
      validate :current_version_must_belong_to_versionable,
               if: :current_version
    end

    private

    # Clear the current version association
    def clear_version
      self.current_version = nil
    end

    # Validate that current version is associated with this versionable
    def current_version_must_belong_to_versionable
      return if current_version.versionable_id == file_id

      errors.add(:current_version, "must belong to this #{model_name}")
    end

    # The attributes that fall under version control
    def versionable_attributes
      {
        file_id: file_id,
        remote_file_id: remote_file_id,
        parent_id: parent_id,
        name: name,
        mime_type: mime_type,
        content_id: content_id,
        thumbnail_id: thumbnail_id
      }
    end

    # Capture a version of this versionable instance
    def version!
      self.current_version = VCS::Version.for(versionable_attributes)
      update_column('current_version_id', current_version.id)
    end
  end
end
