# frozen_string_literal: true

module VCS
  # Class for handling diffing of file versions
  class FileDiff < ApplicationRecord
    include VCS::Diffing

    belongs_to :commit, inverse_of: :file_diffs
    belongs_to :new_version, class_name: 'VCS::Version', optional: true
    belongs_to :old_version, class_name: 'VCS::Version', optional: true

    # Alias
    # TODO: This is for legacy support for Diffing concern. Once old FileDiff
    # => class is deleted, refactor this.
    alias current_version new_version
    alias current_version= new_version=
    alias previous_version old_version
    alias previous_version= old_version=
    alias_attribute :current_version_id, :new_version_id
    alias_attribute :previous_version_id, :old_version_id
    alias_attribute :revision, :commit
    delegate :file_id, to: :current_or_previous_version, prefix: true
    # rubocop:disable Style/Alias
    # FIXME: alias does not seem to work for this delegated attribute
    alias_method :file_resource_id, :current_or_previous_version_file_id
    # rubocop:enable Style/Alias

    # Delegations
    delegate :committed_files, to: :commit

    # Join version on the current version or previous version ID
    scope :joins_current_or_previous_version, lambda {
      joins(
        'INNER JOIN vcs_versions current_or_previous_version '\
        "ON COALESCE(#{table_name}.new_version_id, "\
                    "#{table_name}.old_version_id) "\
        '= current_or_previous_version.id'
      )
    }

    # Order file diffs by
    # 1) directory first and
    # 2) file name in ascending alphabetical order, case insensitive
    scope :order_by_name_with_folders_first, lambda {
      joins_current_or_previous_version.merge(
        FileInBranch.order_by_name_with_folders_first(
          table: 'current_or_previous_version'
        )
      )
    }

    # Include file record id
    scope :with_file_id, lambda {
      joins_current_or_previous_version
        .select(
          "#{table_name}.*",
          'current_or_previous_version.file_id AS file_id'
        )
    }

    # Query diffs by file record ID
    scope :where_file_id, lambda { |file_id|
      with_file_id.where('file_id = ?', file_id)
    }

    # Validations
    # Either current or previous version must be present
    validates :new_version_id, presence: true, unless: :old_version_id
    validates :old_version_id, presence: true, unless: :new_version_id

    # Find diff by hashed file ID
    # Raises ActiveRecord::RecordNotFound error if no match is found.
    def self.find_by_hashed_file_id!(id)
      with_file_id.find_by!(
        current_or_previous_version: {
          file_id: VCS::File.hashid_to_id(id)
        }
      )
    end

    # Apply selected changes to this file diff
    def apply_selected_changes
      # Skip if all changes are selected
      return if changes.all?(&:selected?)

      # apply selected changes
      changes.each(&:apply)

      # persist changes to committed files
      persist_file_to_committed_files
    end

    private

    # Persist current file resource version to the revision's committed files
    def persist_file_to_committed_files
      if new_version_id.present? && new_version_id_was.present?
        update_file_in_committed_files    # Rollback file update

      elsif new_version_id_was.present?
        delete_file_from_committed_files  # Rollback file addition

      elsif new_version_id.present?
        add_file_to_committed_files       # Rollback file deletion
      end
    end

    # Rollback file addition: Delete the file resource from the committed files
    def delete_file_from_committed_files
      committed_files.find_by_version_id(new_version_id_was).destroy
    end

    # Rollback file deletion: Add the file resource to the committed files
    def add_file_to_committed_files
      committed_files.create(version_id: new_version_id)
    end

    # Rollback file update: Update the file resource in the committed files
    def update_file_in_committed_files
      committed_files
        .find_by_version_id(new_version_id_was)
        .update!(version: new_version.version!)
    end
  end
end
