# frozen_string_literal: true

# A contribution to a project (equivalent of pull request/merge request)
class Contribution < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'Profiles::User'
  belongs_to :branch, class_name: 'VCS::Branch',
                      dependent: :destroy,
                      optional: true

  # Delegations
  delegate :branches, :revisions, to: :project, prefix: true

  # Validations
  validates :branch, presence: { message: 'must exist' }, on: %i[create update]
  validates :branch, absence: true, on: :setup
  validates :title, presence: true
  validates :description, presence: true

  # Setup the contribution.
  # Works just like #save/#update but forks off the master branch.
  def setup(attributes = {})
    assign_attributes(attributes)

    return false unless valid?(:setup)

    create_fork_off_master_branch

    save
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_fork_off_master_branch
    # create new branch
    self.branch = project_branches.create!

    # create remote root
    branch.create_remote_root_folder

    # grant write access to contribution creator
    branch.root.remote.grant_write_access_to(creator.account.email)

    # copy files from last commit
    branch.restore_commit(project_revisions.last, author: creator)
  end
  # rubocop:enable Metrics/AbcSize
end
