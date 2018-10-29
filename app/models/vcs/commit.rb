module VCS
  class Commit < ApplicationRecord
    # TODO: Extract Notifying out
    include Notifying

    belongs_to :branch
    has_one :repository, through: :branch
    belongs_to :parent, class_name: 'Commit', optional: true, autosave: false
    belongs_to :author, class_name: 'Profiles::User'
    has_many :children, class_name: 'Commit',
                        foreign_key: :parent_id,
                        dependent: :destroy
    has_many :committed_files, dependent: :delete_all do
      # Get committed files that belong to the provided folder
      def in_folder(folder)
        includes(:file_snapshot)
          .where(
            "#{VCS::FileSnapshot.table_name}": {
              file_record_parent_id: folder.file_record_id
            }
          )
      end
    end
    has_many :committed_snapshots, class_name: 'VCS::FileSnapshot',
                                   through: :committed_files,
                                   source: :file_snapshot
    has_many :file_diffs, -> { order_by_name_with_folders_first },
             inverse_of: :commit, dependent: :delete_all

    # Attributes
    attr_readonly :branch_id, :parent_id, :author_id
    # TODO: Remove. Legacy support only
    alias_attribute :revision, :commit

    # Callbacks
    before_save :apply_selected_file_changes, if: :publishing?
    after_save :update_staged_files, if: :publishing?
    after_save :trigger_notifications, if: %i[publishing? belongs_to_project?]

    # Scopes
    scope :preload_file_diffs_with_snapshots, lambda {
      preload(file_diffs: %i[new_snapshot old_snapshot])
    }

    scope :last_per_branch, lambda {
      select('MAX(id) id, branch_id').published.group(:branch_id)
    }

    scope :published, -> { where(is_published: true) }

    # Validations
    # Require title for published revisions
    validates :title, presence: true, if: :is_published

    validate :parent_must_belong_to_same_branch, if: :parent_id
    validate :can_only_have_one_revision_with_parent, if: :parent_id
    validate :can_only_have_one_origin_revision_per_branch, unless: :parent_id
    validate :selected_file_changes_must_be_valid, if: :publishing?

    # Create a non-published revision for the branch and commit all files staged
    # in the branch
    def self.create_draft_and_commit_files_for_branch!(branch, author)
      create!(branch: branch, parent: branch.commits.last, author: author)
        .tap(&:commit_all_files_staged_in_branch)
        .tap(&:generate_diffs)
    end

    # Take ID and current snapshot ID of all (non-root) file resources currently
    # staged in branch and import them as committed files for this revision.
    def commit_all_files_staged_in_branch
      CommittedFile.insert_from_select_query(
        %i[commit_id file_snapshot_id],
        branch.staged_file_snapshots
              .without_root # only commit non-root snapshots
              .select(id, :id)
      )
    end

    # Return the array of individual changes of this revision
    def file_changes
      file_diffs.flat_map(&:changes)
    end

    # Calculate and cache file diffs from parent revision to self
    def generate_diffs
      FileDiff.where(commit: self).delete_all # Delete all existing diffs
      Operations::FileDiffsCalculator.new(commit: self).cache_diffs!
      file_diffs.reset                          # Reset association
      true                                      # Return success
    end

    # Publish this revision, optionally updating the given attributes
    def publish(attributes_to_update = {})
      update(attributes_to_update.merge(is_published: true))
    end

    def published?
      is_published_in_database
    end

    # Mark the file changes identified by the given IDs as selected and all other
    # file changes as unselected
    def selected_file_change_ids=(ids)
      file_changes.each do |change|
        ids.include?(change.id) ? change.select! : change.unselect!
      end
    end

    # Return all file changes that are NOT selected
    def unselected_file_changes
      file_changes.reject(&:selected?)
    end

    private

    # TODO: Refactor, extract dependency
    def belongs_to_project?
      Project.find_by_repository_id(repository.id).present?
    end

    # Update committed_snapshot_id of staged files
    def update_staged_files
      branch
        .staged_files
        .where('committed_snapshots.file_record_id = vcs_staged_files.file_record_id')
        .update_all(
          'committed_snapshot_id = committed_snapshots.id ' \
          'FROM (' \
          "#{branch.staged_files.joins("LEFT JOIN (#{committed_snapshots.to_sql}) committed_snapshots ON committed_snapshots.file_record_id = vcs_staged_files.file_record_id").select('committed_snapshots.id, vcs_staged_files.file_record_id').to_sql}) committed_snapshots")
    end

    # Apply selected changes to each file diff
    def apply_selected_file_changes
      # Skip if all changes are selected
      return if unselected_file_changes.none?

      # Apply changes on each diff
      file_diffs.each(&:apply_selected_changes)

      # Re-generate diffs
      generate_diffs
    end

    def can_only_have_one_origin_revision_per_branch
      return unless published_origin_revision_exists_for_branch?

      errors.add(:base, 'An origin revision already exists for this branch')
    end

    def can_only_have_one_revision_with_parent
      return unless published_revision_with_parent_exists?

      errors.add(:base,
                 'Someone has captured changes to this branch since you ' \
                 'started reviewing changes. To prevent you and your team from ' \
                 "overwriting each other's changes, you cannot capture the " \
                 'changes you are currently reviewing.')
    end

    def parent_must_belong_to_same_branch
      return if parent.branch_id == branch_id

      errors.add(:parent, 'must belong to same branch')
    end

    def published_origin_revision_exists_for_branch?
      self.class.exists?(branch_id: branch_id, parent: nil, is_published: true)
    end

    def published_revision_with_parent_exists?
      self.class.exists?(parent_id: parent_id, is_published: true)
    end

    # Return true if revision is currently being published
    def publishing?
      is_published &&
        (will_save_change_to_is_published? || saved_change_to_is_published?)
    end

    def selected_file_changes_must_be_valid
      # Skip if all changes are selected
      return if unselected_file_changes.none?

      file_changes.select(&:selected?).each do |file_change|
        next if file_change.valid?

        errors[:base].push(*file_change.errors.full_messages)
      end
    end
  end
end
