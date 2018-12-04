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

    # Capture a version of this versionable instance
    def version!
      self.current_version =
        VCS::Version.for(attributes.merge(file_id: file_id))
      # find_or_create_current_version_by!(core_version_attributes,
      #                                     supplemental_version_attributes)
      update_column('current_version_id', current_version.id)
    end
  end
end
