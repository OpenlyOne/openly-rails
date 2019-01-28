# frozen_string_literal: true

# Controller for project file infos
class FileInfosController < Abstract::FileInfosController
  private

  def link_path_prefix
    'profile_project_'
  end

  def path_parameters
    [@project.owner, @project]
  end

  def set_branch
    @branch = @master_branch
  end

  def set_user_can_force_sync_files
    @user_can_force_sync_files = can?(:force_sync, @project)
  end

  def set_user_can_restore_files
    @user_can_restore_files = can?(:restore_file, @project)
  end

  def set_user_can_view_file_in_branch
    @user_can_view_file_in_branch = can?(:show, :file_in_branch, @project)
  end

  def uncaptured_file_diff_present?
    @uncaptured_file_diff.present?
  end
end
