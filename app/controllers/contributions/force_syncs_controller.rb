# frozen_string_literal: true

module Contributions
  # Controller for force syncing files of contributions
  class ForceSyncsController < Abstract::ForceSyncsController
    private

    def authorize_action
      authorize! :force_sync, @contribution
    end

    def file_info_path
      profile_project_contribution_file_infos_path(
        @project.owner,
        @project,
        @contribution,
        @file || params[:id]
      )
    end

    def set_branch
      @branch = @contribution.branch
    end

    def set_object
      @contribution = @project.contributions.find(params[:contribution_id])
    end
  end
end
