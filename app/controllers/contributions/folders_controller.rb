# frozen_string_literal: true

module Contributions
  # File browsing actions for a project contribution
  class FoldersController < Abstract::FoldersController
    private

    def link_path_prefix
      'profile_project_contribution_'
    end

    def path_parameters
      [@project.owner, @project, @contribution]
    end

    def require_authentication?
      false
    end

    def set_object
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    def set_branch
      @branch = @contribution.branch
    end
  end
end
