module VCS
  class StagedFile < ApplicationRecord
    belongs_to :branch
    belongs_to :file_record
    belongs_to :file_record_parent, class_name: 'FileRecord', optional: true

    belongs_to :committed_snapshot, class_name: 'VCS::FileSnapshot', optional: true
    belongs_to :current_snapshot, class_name: 'VCS::FileSnapshot', optional: true

    include VCS::Resourceable
    include VCS::Snapshotable
    # include Stageable
    include VCS::Syncable
    # must be last, so that backup is made after snapshot is persisted
    include VCS::Backupable

    # Associations
    # has_one :parent, ->(staged_file) { where(file_record_id: staged_file.file_record_parent_id) },
    #         class_name: model_name,
    #         through: :branch,
    #         source: :staged_files
    # has_many :children, ->(staged_file) { where(file_record_parent_id: staged_file.file_record_id) },
    #          through: :branch,
    #          source: :staged_files

    scope :joins_staged_snapshot, lambda {
      joins(
        'INNER JOIN vcs_file_snapshots staged_snapshots ' \
        "ON (COALESCE(#{table_name}.current_snapshot_id, "\
                     "#{table_name}.committed_snapshot_id) "\
        '= staged_snapshots.id)'
      )
    }

    # TODO: Move to a different class
    # for this model, add joins_staged_snapshot
    scope :order_by_name_with_folders_first, lambda { |table: nil|
      folder_mime_type = Providers::GoogleDrive::MimeType.folder
      table ||= 'staged_snapshots'

      order(
        Arel.sql(
          "#{table}.mime_type IN (#{connection.quote(folder_mime_type)}) desc, " \
          "#{table}.name asc"
        )
      )
    }

    # has_many :snapshots, class_name: 'VCS::FileSnapshot', foreign_key: :file_record_id

    # scope :with_committed_snapshot, lambda {
    #   select("#{table_name}.*", 'committed_snapshots.id AS committed_snapshot_id')
    #     .joins("INNER JOIN (#{VCS::Commit.last_per_branch.to_sql}) last_commits ON last_commits.branch_id = vcs_staged_files.branch_id")
    #     .joins("INNER JOIN vcs_committed_files ON vcs_committed_files.commit_id = last_commits.id")
    #     .joins("INNER JOIN vcs_file_snapshots committed_snapshots ON (committed_snapshots.file_record_id = vcs_staged_files.file_record_id AND committed_snapshots.id = vcs_committed_files.file_snapshot_id)")
    # }
    #
    # scope :with_current_or_committed_snapshot, lambda {
    #   select(
    #     "#{table_name}.*",
    #     'files_in_last_commit.committed_snapshot_id AS committed_snapshot_id'
    #   )
    #     .left_joins(:current_snapshot)
    #     .joins(<<-SQL.squish
    #       LEFT JOIN (#{VCS::StagedFile.with_committed_snapshot.to_sql})
    #       files_in_last_commit ON files_in_last_commit.id = vcs_staged_files.id
    #       SQL
    #     ).where('vcs_staged_files.current_snapshot_id IS NOT NULL OR files_in_last_commit.id IS NOT NULL')
    # }
    #
    # scope :joins_current_or_committed_snapshot, lambda {
    #   with_current_or_committed_snapshot
    #     .joins(
    #       'INNER JOIN vcs_file_snapshots current_or_previous_snapshots ' \
    #       "ON (COALESCE(#{table_name}.current_snapshot_id, "\
    #                    'committed_snapshot_id) '\
    #       '= current_or_previous_snapshots.id)'
    #     )
    # }
    #
    # scope :with_current_or_committed_snapshot_in_folder, lambda { |folder|
    #   joins_current_or_committed_snapshot
    #     .where(
    #       'current_or_previous_snapshots.file_record_parent_id = ?',
    #       folder.file_record_id
    #     )
    # }

    # Validations
    validates :external_id, presence: true
    validates :external_id, uniqueness: { scope: :branch_id },
                            if: :will_save_change_to_external_id?

    # validate :cannot_be_its_own_parent, if: :parent_association_loaded?

    # Only perform validation if no errors have been encountered
    with_options unless: :any_errors? do
      validate :cannot_be_its_own_ancestor,
               if: :will_save_change_to_file_record_parent_id?
    end

    # Require presence of metadata unless file resource is deleted
    with_options unless: :deleted? do
      # TODO: Refactor. Must use if: :not_root? because unless: :root? would
      # => overwrite top level condition.
      # See: https://stackoverflow.com/a/15388137/6451879
      validates :file_record_parent_id, presence: true, if: :not_root?
      validates :name, presence: true
      validates :mime_type, presence: true
      validates :content_version, presence: true
    end

    # Recursively collect parents
    def ancestors
      return [] if parent.nil? || parent.root?

      [parent.staged_snapshot] + parent.ancestors
    end

    # Recursively collect ids of parents
    def ancestors_ids
      ancestors.map(&:file_record_id)
    end

    def children
      @children ||=
        branch
        .staged_files
        .joins_staged_snapshot
        .where('staged_snapshots.file_record_parent_id = ?', file_record_id)
    end

    def staged_children=(new_children)
      new_children.each { |child| child.update(parent: self) }

      staged_children.where.not(id: new_children.map(&:id)).find_each(&:pull)

      # Clear children because they are no longer accurate, as STAGED children
      # have changed and status of committed children is unclear
      @children = nil
    end

    def staged_children
      branch
        .staged_files
        .joins(:current_snapshot)
        .where(
          "#{VCS::FileSnapshot.table_name}": {
            file_record_parent_id: file_record_id
          }
        )
    end

    def parent
      @parent ||=
        branch
        .staged_files
        .joins_staged_snapshot
        .find_by('staged_snapshots.file_record_id = ?', staged_snapshot&.file_record_parent_id)
    end

    def parent=(new_parent)
      if new_parent.present?
        self.file_record_parent_id = new_parent.file_record_id
        @parent = new_parent
      else
        mark_as_removed unless root?
      end
    end

    # TODO: Rename is_deleted to is_removed
    def mark_as_removed
      assign_attributes(file_record_parent_id: nil, name: nil, mime_type: nil, content_version: nil, is_deleted: true)
    end

    def staged_snapshot
      current_snapshot || committed_snapshot
    end

    def diff(with_ancestry: false)
      @diff ||=
        VCS::FileDiff.new.tap do |diff|
          diff.new_snapshot_id = current_snapshot_id
          diff.old_snapshot_id = committed_snapshot_id
          # TODO: Add depth option for ancestry. Should be max 3
          diff.first_three_ancestors = ancestors.map(&:name) if with_ancestry
        end
    end

    def deleted?
      is_deleted
    end

    def folder?
      Object.const_get("#{provider}::MimeType").folder?(mime_type)
    end

    def root?
      is_root
    end

    def not_root?
      !root?
    end

    # Return all children that are folders
    def subfolders
      staged_children.select(&:folder?)
    end

    private

    def any_errors?
      errors.any?
    end

    def cannot_be_its_own_ancestor
      return unless ancestors_ids.include? file_record_id

      errors.add(:base, 'File resource cannot be its own ancestor')
    end

    def cannot_be_its_own_parent
      return unless self == parent

      errors.add(:base, 'File resource cannot be its own parent')
    end

    def parent_association_loaded?
      association(:parent).loaded?
    end
  end
end
