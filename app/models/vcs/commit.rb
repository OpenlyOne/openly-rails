# frozen_string_literal: true

module VCS
  # A commit is a version of a branch with all its files
  # rubocop:disable Metrics/ClassLength
  class Commit < ApplicationRecord
    # TODO: Extract Notifying out
    include Notifying

    # Associations
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
        includes(:version)
          .where(
            "#{VCS::Version.table_name}": {
              parent_id: folder.file_id
            }
          )
      end
    end
    has_many :committed_versions, class_name: 'VCS::Version',
                                  through: :committed_files,
                                  source: :version
    has_many :file_diffs, -> { order_by_name_with_folders_first },
             inverse_of: :commit, dependent: :delete_all

    # Attributes
    # HACK: Set to true to force select all attributes and not selectively
    # =>    commit changes
    attr_accessor :select_all_file_changes
    attr_readonly :parent_id
    # TODO: Remove. Legacy support only
    alias_attribute :revision, :commit

    # Callbacks
    before_save :apply_selected_file_changes,
                if: :publishing?, unless: :select_all_file_changes
    after_save :update_files_in_branch, if: :publishing?
    after_save :trigger_notifications, if: %i[publishing? belongs_to_project?]

    # Scopes
    scope :preload_file_diffs_with_versions, lambda {
      preload(scope_for_preloading_file_diffs_with_versions)
    }

    scope :published, -> { where(is_published: true) }

    # Validations
    # Require title for published revisions
    validates :title, presence: true, if: :is_published

    validate :parent_must_belong_to_same_repository, if: :parent_id
    validate :can_only_have_one_revision_with_parent, if: :parent_id
    validate :can_only_have_one_origin_revision_per_branch, unless: :parent_id
    validate :selected_file_changes_must_be_valid,
             if: :publishing?, unless: :select_all_file_changes
    validate :cannot_change_branch_id, if: :published?

    # Create a non-published revision for the branch and commit all files in the
    # branch
    def self.create_draft_and_commit_files_for_branch!(branch, author)
      create!(branch: branch, parent: branch.commits.last, author: author)
        .tap(&:commit_all_files_in_branch)
        .tap(&:generate_diffs)
    end

    # File diffs & associations to preload
    def self.scope_for_preloading_file_diffs_with_versions
      {
        file_diffs: {
          new_version: %i[backup content],
          old_version: %i[backup content]
        }
      }
    end

    # Take ID and current version ID of all (non-root) files currently in
    # branch and import them as committed files for this revision.
    def commit_all_files_in_branch
      VCS::CommittedFile.insert_from_select_query(
        %i[commit_id version_id],
        branch.versions_in_branch
              .without_root # only commit non-root versions
              .select(id, :id)
      )
    end

    # Return the array of individual changes of this revision
    def file_changes
      file_diffs.flat_map(&:changes)
    end

    # Calculate and cache file diffs from parent revision to self
    def generate_diffs
      VCS::FileDiff.where(commit: self).delete_all # Delete all existing diffs
      VCS::Operations::FileDiffsCalculator.new(commit: self).cache_diffs!
      file_diffs.reset                          # Reset association
      true                                      # Return success
    end

    # Preload file diffs and versions for a single instance
    def preload_file_diffs_with_versions
      ActiveRecord::Associations::Preloader.new.preload(
        Array(self),
        self.class.scope_for_preloading_file_diffs_with_versions
      )
    end

    # Publish this revision, optionally updating the given attributes
    def publish(attributes_to_update = {})
      update(attributes_to_update.merge(is_published: true))
    end

    def published?
      is_published_in_database
    end

    # Mark the file changes identified by the given IDs as selected and all
    # other file changes as unselected
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

    # Update each file in stage by joining it onto committed versions via
    # file record id and setting the committed_version_id of files to the id of
    # committed versions
    # rubocop:disable Metrics/MethodLength
    def update_files_in_branch
      # Left join files on committed versions
      # TODO: Extract into scope/query
      files_in_branch_left_joining_committed_versions =
        branch.files.joins(
          <<~SQL
            LEFT JOIN (#{committed_versions.to_sql}) committed_versions
            ON (committed_versions.file_id =
            vcs_file_in_branches.file_id)
          SQL
        ).select('committed_versions.id, vcs_file_in_branches.file_id')

      # Perform the update
      branch
        .files
        .where(
          'committed_versions.file_id = ' \
          'vcs_file_in_branches.file_id'
        ).update_all(
          <<~SQL
            committed_version_id = committed_versions.id
            FROM (#{files_in_branch_left_joining_committed_versions.to_sql})
            committed_versions
          SQL
        )
    end
    # rubocop:enable Metrics/MethodLength

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
                 'started reviewing changes. To prevent you and your team ' \
                 "from overwriting each other's changes, you cannot capture " \
                 'the changes you are currently reviewing.')
    end

    def cannot_change_branch_id
      errors.add(:branch, 'is readonly') if branch_id_changed?
    end

    def parent_must_belong_to_same_repository
      return if parent.repository.id == branch.repository_id

      errors.add(:parent, 'must belong to same repository')
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
  # rubocop:enable Metrics/ClassLength
end
