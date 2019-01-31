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
  delegate :branches, :master_branch, :revisions, to: :project, prefix: true
  delegate :files, to: :branch

  # Validations
  validates :branch, presence: { message: 'must exist' }, on: %i[create update]
  validates :branch, absence: true, on: :setup
  validates :title, presence: true
  validates :description, presence: true

  def accepted?
    is_accepted
  end

  def open?
    !accepted?
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

  def fork_master_branch
    self.branch = project_master_branch.create_fork(creator: creator)
  end

  def grant_creator_write_access_to_branch
    branch.root.remote.grant_write_access_to(creator.account.email)
  end
end
