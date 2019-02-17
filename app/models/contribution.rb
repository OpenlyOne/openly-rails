# frozen_string_literal: true

# A contribution to a project (equivalent of pull request/merge request)
# rubocop:disable Metrics/ClassLength
class Contribution < ApplicationRecord
  include Notifying

  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'Profiles::User'
  belongs_to :branch, class_name: 'VCS::Branch',
                      dependent: :destroy,
                      optional: true
  belongs_to :origin_revision, class_name: 'VCS::Commit'
  belongs_to :accepted_revision, class_name: 'VCS::Commit', optional: true

  # Attributes
  # Transient revision attribute
  attr_accessor :revision

  # Callbacks
  before_save :publish_accepted_revision, if: :accepting?
  after_create :trigger_create_notifications

  # Delegations
  delegate :branches, :master_branch, :revisions, to: :project, prefix: true
  delegate :files, to: :branch
  delegate :id, to: :revision, prefix: true

  # Validations
  validates :branch, presence: { message: 'must exist' }, on: %i[create update]
  validates :branch, absence: true, on: :setup
  validates :title, presence: true
  validates :description, presence: true
  validate :cannot_have_been_accepted, on: :accept
  validate :origin_revision_must_be_published
  validate :origin_revision_must_belong_to_project_master_branch

  def accepted?
    accepted_revision_id_in_database.present?
  end

  def open?
    !accepted?
  end

  # Accept the provided revision
  def accept(revision:)
    return false unless update_with_context({ accepted_revision: revision },
                                            :accept)

    # Apply suggested changes onto files in master branch
    VCS::Operations::RestoreFilesFromDiffs.restore(
      file_diffs: accepted_revision.file_diffs.includes(:new_version),
      target_branch: project.master_branch
    )

    # Return true
    true
  end

  # Calculate the file changes suggested by this contribution
  # TODO: Factor author out of this
  def suggested_file_diffs
    @suggested_file_diffs ||=
      branch
      .all_commits.create!(parent: origin_revision, author: creator)
      .tap(&:commit_all_files_in_branch)
      .tap(&:generate_diffs)
      .file_diffs.includes(:new_version, :old_version)
  end

  # Build the revision to be accepted
  # TODO: Factor author out of this
  # rubocop:disable Metrics/AbcSize
  def prepare_revision_for_acceptance(author:)
    # Create commit draft
    self.revision = branch.all_commits.create!(
      parent: project.revisions.last,
      author: author,
      title: title,
      summary: description
    )

    # Calculate committed files by applying suggested changes on top of
    # committed files in last master commit
    revision.copy_committed_files_from(revision.parent)
    revision.apply_file_diffs_to_committed_files(suggested_file_diffs)

    # Calculate diffs
    revision.tap(&:generate_diffs).tap(&:preload_file_diffs_with_versions)
  end
  # rubocop:enable Metrics/AbcSize

  # Setup the contribution.
  # Works just like #save/#update but forks off the master branch.
  def setup(attributes = {})
    assign_attributes(attributes)

    return false unless valid?(:setup)

    fork_master_branch
    grant_creator_write_access_to_branch

    save
  end

  private

  # Return true if contribution is currently being accepted
  def accepting?
    accepted_revision_id.present? &&
      (will_save_change_to_accepted_revision_id? ||
       saved_change_to_accepted_revision_id?)
  end

  def fork_master_branch
    self.branch = project_master_branch.create_fork(
      creator: creator,
      remote_parent_id: project.archive.remote_file_id,
      commit: origin_revision
    )
  end

  def grant_creator_write_access_to_branch
    branch.root.remote.grant_write_access_to(creator.account.email)
  end

  def cannot_have_been_accepted
    errors.add(:base, 'Contribution has already been accepted.') if accepted?
  end

  def origin_revision_must_be_published
    return if origin_revision&.published?

    errors.add(:origin_revision, 'must be published')
  end

  def origin_revision_must_belong_to_project_master_branch
    return if origin_revision&.branch_id.present? &&
              project&.master_branch_id.present? &&
              origin_revision.branch_id == project.master_branch_id

    errors.add(:origin_revision, 'must belong to the same project')
  end

  def publish_accepted_revision
    return unless accepted_revision.present?

    throw(:abort) unless accepted_revision.publish(
      branch_id: project.master_branch_id,
      select_all_file_changes: true,
      author_id: creator_id
    )
  end

  def trigger_create_notifications
    trigger_notifications('contribution.create')
  end
end
# rubocop:enable Metrics/ClassLength
