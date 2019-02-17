# frozen_string_literal: true

module Contributions
  # Controller for reviewing changes suggested by a contribution
  class ReviewsController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_contribution
    before_action :set_revision, if: :contribution_accepted?
    before_action :prepare_revision_for_acceptance,
                  unless: :contribution_accepted?
    before_action :set_user_can_accept_contribution,
                  unless: :contribution_accepted?

    def show
      if contribution_accepted?
        render 'show_accepted_changes'
      else
        render 'show_suggested_changes'
      end
    end

    private

    def contribution_accepted?
      @contribution.accepted?
    end

    def prepare_revision_for_acceptance
      @contribution
        .prepare_revision_for_acceptance(author: current_user_or_fallback)
    end

    def set_contribution
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    def set_revision
      @revision =
        @contribution.accepted_revision.tap(&:preload_file_diffs_with_versions)
    end

    def set_user_can_accept_contribution
      @user_can_accept_contribution = can?(:accept, @contribution)
    end

    # Return the current user or fall back to the contribution creator
    # TODO: Remove when we refactor author requirement from commit
    def current_user_or_fallback
      current_user || @contribution.creator
    end
  end
end
