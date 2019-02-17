# frozen_string_literal: true

module Contributions
  # Controller for reviewing changes suggested by a contribution
  class AcceptancesController < ApplicationController
    include CanSetProjectContext

    before_action :authenticate_account!
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_contribution
    before_action :authorize_action
    before_action :find_revision

    # TODO: Refactor
    # rubocop:disable Metrics/MethodLength
    def create
      if @contribution.accept(revision: @revision)
        # Successfully accepted
        redirect_with_success_to(
          profile_project_root_folder_path(@project.owner, @project),
          notice: 'Contribution successfully accepted. ' \
                  'Suggested changes are being applied...'
        )
      else
        # Error occurred while accepting contribution
        @user_can_accept_contribution = true
        @revision.preload_file_diffs_with_versions
        render 'contributions/reviews/show_suggested_changes',
               layout: 'contributions/reviews'
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def authorize_action
      authorize! :accept, @contribution
    end

    def can_can_access_denied(exception)
      super || redirect_to(contribution_review_path, alert: exception.message)
    end

    def contribution_review_path
      profile_project_contribution_review_path(
        @project.owner, @project, @contribution
      )
    end

    def find_revision
      @revision = VCS::Commit.find_by!(
        id: contribution_params[:revision_id],
        branch: @contribution.branch,
        author: current_user,
        is_published: false
      )
    end

    def set_contribution
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    def contribution_params
      params.require(:contribution).permit(:revision_id)
    end
  end
end
