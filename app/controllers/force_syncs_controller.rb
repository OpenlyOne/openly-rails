# frozen_string_literal: true

# Controller for force syncing files
class ForceSyncsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!
  before_action :set_project
  before_action :authorize_project_access
  before_action :authorize_action
  before_action :set_staged_file_diff
  before_action :set_file_resource

  def create
    @file.pull
    @file.pull_children if @file.folder?

    redirect_to file_info_path, notice: 'File successfully synced.'
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! :force_sync, @project
  end

  def can_can_access_denied(exception)
    super || redirect_to(file_info_path, alert: exception.message)
  end

  def file_id
    params[:id]
  end

  def file_info_path
    profile_project_file_infos_path(@project.owner, @project, file_id)
  end

  # Set the file resource
  def set_file_resource
    @file = FileResources::GoogleDrive.find_by!(external_id: file_id)
  end

  # Attempt to find the file diff of stage (base) and last revision
  # (differentiator)
  def set_staged_file_diff
    @staged_file_diff = Stage::FileDiff.find_by!(external_id: file_id,
                                                 project: @project)
  end
end
