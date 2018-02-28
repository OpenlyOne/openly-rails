# frozen_string_literal: true

# Revisions represent a snapshot of a project with all its files
class Revision < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :parent, class_name: 'Revision', optional: true, autosave: false
  belongs_to :author, class_name: 'Profiles::User'
  has_many :committed_files, dependent: :destroy

  # attributes
  attr_readonly :project_id, :parent_id, :author_id

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
            parent: project.published_revisions.last,
            author: author)
      .tap(&:commit_all_files_staged_in_project)
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
               'Someone has committed changes to this project since you ' \
               'started reviewing changes. To prevent you and your team from' \
               "overwriting each other's changes, you cannot commit the " \
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
end
