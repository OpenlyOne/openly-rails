# frozen_string_literal: true

module Contributions
  # Controller for project file infos
  class FileChangesController < Abstract::FileChangesController
    private

    def set_branch
      @branch = @contribution.branch
    end

    def set_object
      @contribution = @project.contributions.find(params[:contribution_id])
    end
  end
end
