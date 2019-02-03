# frozen_string_literal: true

# A contribution to a project (equivalent of pull request/merge request)
class Contribution < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'Profiles::User'
  belongs_to :branch, class_name: 'VCS::Branch',
                      dependent: :destroy,
                      optional: true

  # Attributes
  # Transient revision attribute
  attr_accessor :revision

  # Callbacks
  before_save :publish_revision, if: :accepting?

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

  def accepted?
    is_accepted_in_database
  end

  def open?
    !accepted?
  end

  # Accept the provided revision
  def accept(revision:)
    return false unless update_with_context({ is_accepted: true,
                                              revision: revision },
                                            :accept)

    # TODO: Factor author/creator out of this
    project.master_branch.restore_commit(revision, author: creator)

    # Return true
    true
  end

  # Build the revision to be accepted
  # TODO: Factor author out of this
  def prepare_revision_for_acceptance(author:)
    # Create commit draft
    self.revision = branch.all_commits.create!(
      parent: project.revisions.last,
      author: author,
      title: title,
      summary: description
    )

    # Generate & load diffs
    revision
      .tap(&:commit_all_files_in_branch)
      .tap(&:generate_diffs)
      .tap(&:preload_file_diffs_with_versions)
  end

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
    is_accepted &&
      (will_save_change_to_is_accepted? || saved_change_to_is_accepted?)
  end

  def fork_master_branch
    self.branch = project_master_branch.create_fork(
      creator: creator,
      remote_parent_id: project.archive.remote_file_id
    )
  end

  def grant_creator_write_access_to_branch
    branch.root.remote.grant_write_access_to(creator.account.email)
  end

  def cannot_have_been_accepted
    errors.add(:base, 'Contribution has already been accepted.') if accepted?
  end

  def publish_revision
    return unless revision.present?

    throw(:abort) unless revision.publish(branch_id: project.master_branch_id,
                                          select_all_file_changes: true,
                                          author_id: creator_id)
  end
end
