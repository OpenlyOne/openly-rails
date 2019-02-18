# frozen_string_literal: true

# Define user permissions
class Ability
  include CanCan::Ability

  # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
  # rubocop: disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def initialize(user)
    # Users can view public projects and private projects they are collaborators
    # of
    can %i[access], Project do |project|
      project.public? || can?(:collaborate, project)
    end

    # ALL METHODS BELOW THIS LINE REQUIRE AUTHENTICATION
    return unless user

    # Users can manage their own profiles
    can :manage, Profiles::User, id: user.id

    # Users can collaborate on projects that they own or are a collaborator of
    can :collaborate, Project do |project|
      can?(:edit, project) || project.collaborators.exists?(user.id)
    end

    can :create, Project do |project|
      # Users can only create projects for profiles they can manage
      can?(:manage, project.owner) &&
        ( # All users can create non-private projects.
          !project.private? ||
          # Premium users can create private projects.
          (project.private? && user.premium_account?)
        )
    end

    # Users can edit the projects of profiles that they can manage
    can %i[edit update destroy], Project do |project|
      can? :manage, project.owner
    end

    # User can view files in branchc for projects in which they collaborate
    can :show, :file_in_branch do |_file_in_branch, project|
      can?(:collaborate, project)
    end

    # User can force sync and restore files & setup for projects in which they
    # collaborate
    can %i[force_sync restore_file restore_revision setup], Project do |project|
      can?(:collaborate, project)
    end

    # User can commit changes for projects of profiles that they can manage
    # or of which they are a collaborator
    can %i[new create], :revision do |_revision, project|
      can?(:collaborate, project)
    end

    # Users can create contributions for projects that they can access
    # Users can reply to contributions of projects that they can access
    can %i[new create reply], Contribution do |contribution|
      can?(:access, contribution.project)
    end

    # User can accept contributions for projects that they are collaborators of
    can %i[accept], Contribution do |contribution|
      can?(:collaborate, contribution.project)
    end

    # User can force sync for contributions which they created
    can %i[force_sync], Contribution, creator_id: user.id

    # Admins can use the administration back end
    return unless user.admin?

    can :manage, :admin_panel

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
  # rubocop: enable Metrics/MethodLength, Metrics/AbcSize
  # rubocop: enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
