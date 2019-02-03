# frozen_string_literal: true

# Controller for force syncing files
class ForceSyncsController < Abstract::ForceSyncsController
  private

  def authorize_action
    authorize! :force_sync, @project
  end

  def file_info_path
    profile_project_file_infos_path(
      @project.owner,
      @project,
      @file || params[:id]
    )
  end

  def set_branch
    @branch = @master_branch
  end
end
