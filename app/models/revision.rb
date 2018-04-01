# frozen_string_literal: true

# Revisions represent a snapshot of a project with all its files
class Revision < ApplicationRecord
  include Notifying

  # Associations
  belongs_to :project
  belongs_to :parent, class_name: 'Revision', optional: true, autosave: false
  belongs_to :author, class_name: 'Profiles::User'
  has_many :children, class_name: 'Revision',
                      foreign_key: :parent_id,
                      dependent: :destroy
  has_many :committed_files, dependent: :delete_all
  has_many :committed_file_snapshots, class_name: 'FileResource::Snapshot',
                                      through: :committed_files,
                                      source: :file_resource_snapshot
  has_many :file_diffs, -> { order_by_name_with_folders_first },
           dependent: :destroy

  # Attributes
  attr_readonly :project_id, :parent_id, :author_id

  # Callbacks
  after_save :trigger_notifications, if: :publishing?

  # Scopes
  scope :preload_file_diffs_with_snapshots, lambda {
    preload(file_diffs: %i[current_snapshot previous_snapshot])
  }

  # Validations
  # Require title for published revisions
  validates :title, presence: true, if: :published?

  validate :parent_must_belong_to_same_project, if: :parent_id
  validate :can_only_have_one_revision_with_parent, if: :parent_id
  validate :can_only_have_one_origin_revision_per_project, unless: :parent_id

  # Create a non-published revision for the project and commit all files staged
  # in the project
  def self.create_draft_and_commit_files_for_project!(project, author)
    create!(project: project,
            parent: project.revisions.last,
            author: author)
      .tap(&:commit_all_files_staged_in_project)
      .tap(&:generate_diffs)
  end

  # Take ID and current snapshot ID of all (non-root) file resources currently
  # staged in project and import them as committed files for this revision.
  def commit_all_files_staged_in_project
    CommittedFile.insert_from_select_query(
      %i[revision_id file_resource_id file_resource_snapshot_id],
      project.non_root_file_resources_in_stage  # only commit non-root files
             .with_current_snapshot             # ignore files without snapshot
             .select(id, :id, :current_snapshot_id)
    )
  end

  # Return the array of individual changes of this revision
  def file_changes
    file_diffs.flat_map(&:changes)
  end

  # Calculate and cache file diffs from parent revision to self
  def generate_diffs
    FileDiffsCalculator.new(revision: self).cache_diffs!
  end

  def published?
    is_published
  end

  private

  def can_only_have_one_origin_revision_per_project
    return unless published_origin_revision_exists_for_project?
    errors.add(:base, 'An origin revision already exists for this project')
  end

  def can_only_have_one_revision_with_parent
    return unless published_revision_with_parent_exists?
    errors.add(:base,
               'Someone has captured changes to this project since you ' \
               'started reviewing changes. To prevent you and your team from ' \
               "overwriting each other's changes, you cannot capture the " \
               'changes you are currently reviewing.')
  end

  def parent_must_belong_to_same_project
    return if parent.project_id == project_id
    errors.add(:parent, 'must belong to same project')
  end

  def published_origin_revision_exists_for_project?
    self.class.exists?(project_id: project_id, parent: nil, is_published: true)
  end

  def published_revision_with_parent_exists?
    self.class.exists?(parent_id: parent_id, is_published: true)
  end

  # Return true if revision is currently being published
  def publishing?
    published? && saved_change_to_is_published?
  end
end
