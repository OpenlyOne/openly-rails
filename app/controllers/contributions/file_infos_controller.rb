# frozen_string_literal: true

module Contributions
  # Controller for project file infos within a contribution
  class FileInfosController < Abstract::FileInfosController
    private

    def link_path_prefix
      'profile_project_contribution_'
    end

    def path_parameters
      [@project.owner, @project, @contribution]
    end

    def set_branch
      @branch = @contribution.branch
    end

    def set_object
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    # TODO: Only contribution creator can force sync files in contribution
    def set_user_can_force_sync_files
      @user_can_force_sync_files = false
      # @user_can_force_sync_files = can?(:force_sync, @project)
    end

    # TODO: Only contribution creator can restore files in contribution
    def set_user_can_restore_files
      @user_can_restore_files = false
      # @user_can_restore_files = can?(:restore_file, @project)
    end

    # Any user can view files in branch for contributions
    def set_user_can_view_file_in_branch
      @user_can_view_file_in_branch = true
    end
  end
end
