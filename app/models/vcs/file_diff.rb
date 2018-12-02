# frozen_string_literal: true

module VCS
  # Class for handling diffing of file snapshots
  class FileDiff < ApplicationRecord
    include VCS::Diffing

    belongs_to :commit, inverse_of: :file_diffs
    belongs_to :new_snapshot, class_name: 'FileSnapshot', optional: true
    belongs_to :old_snapshot, class_name: 'FileSnapshot', optional: true

    # Alias
    # TODO: This is for legacy support for Diffing concern. Once old FileDiff
    # => class is deleted, refactor this.
    alias current_snapshot new_snapshot
    alias current_snapshot= new_snapshot=
    alias previous_snapshot old_snapshot
    alias previous_snapshot= old_snapshot=
    alias_attribute :current_snapshot_id, :new_snapshot_id
    alias_attribute :previous_snapshot_id, :old_snapshot_id
    alias_attribute :revision, :commit
    delegate :file_record_id, to: :current_or_previous_snapshot, prefix: true
    # rubocop:disable Style/Alias
    # FIXME: alias does not seem to work for this delegated attribute
    alias_method :file_resource_id, :current_or_previous_snapshot_file_record_id
    # rubocop:enable Style/Alias

    # Delegations
    delegate :committed_files, to: :commit

    # Join snapshot on the current snapshot or previous snapshot ID
    scope :joins_current_or_previous_snapshot, lambda {
      joins(
        'INNER JOIN vcs_file_snapshots current_or_previous_snapshot '\
        "ON COALESCE(#{table_name}.new_snapshot_id, "\
                    "#{table_name}.old_snapshot_id) "\
        '= current_or_previous_snapshot.id'
      )
    }

    # Order file diffs by
    # 1) directory first and
    # 2) file name in ascending alphabetical order, case insensitive
    scope :order_by_name_with_folders_first, lambda {
      joins_current_or_previous_snapshot.merge(
        FileInBranch.order_by_name_with_folders_first(
          table: 'current_or_previous_snapshot'
        )
      )
    }

    # Include file record id
    scope :with_file_record_id, lambda {
      joins_current_or_previous_snapshot
        .select(
          "#{table_name}.*",
          'current_or_previous_snapshot.file_record_id AS file_record_id'
        )
    }

    # Query diffs by file record ID
    scope :where_file_record_id, lambda { |file_record_id|
      with_file_record_id.where('file_record_id = ?', file_record_id)
    }

    # Validations
    # Either current or previous snapshot must be present
    validates :new_snapshot_id, presence: true, unless: :old_snapshot_id
    validates :old_snapshot_id, presence: true, unless: :new_snapshot_id

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

    # Persist current file resource snapshot to the revision's committed files
    def persist_file_to_committed_files
      if new_snapshot_id.present? && new_snapshot_id_was.present?
        update_file_in_committed_files    # Rollback file update

      elsif new_snapshot_id_was.present?
        delete_file_from_committed_files  # Rollback file addition

      elsif new_snapshot_id.present?
        add_file_to_committed_files       # Rollback file deletion
      end
    end

    # Rollback file addition: Delete the file resource from the committed files
    def delete_file_from_committed_files
      committed_files.find_by_file_snapshot_id(new_snapshot_id_was).destroy
    end

    # Rollback file deletion: Add the file resource to the committed files
    def add_file_to_committed_files
      committed_files.create(file_snapshot_id: new_snapshot_id)
    end

    # Rollback file update: Update the file resource in the committed files
    def update_file_in_committed_files
      committed_files
        .find_by_file_snapshot_id(new_snapshot_id_was)
        .update!(file_snapshot: new_snapshot.snapshot!)
    end
  end
end
