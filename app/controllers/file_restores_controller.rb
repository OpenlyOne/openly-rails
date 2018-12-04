# frozen_string_literal: true

# Controller for restoring an individual file to a prior version
class FileRestoresController < ApplicationController
  include CanSetProjectContext

  before_action :set_file_version
  before_action :authenticate_account!
  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :authorize_action

  def create
    VCS::Operations::FileRestore.new(
      version: @version,
      target_branch: @master_branch
    ).restore

    redirect_to file_info_path, notice: 'File successfully restored.'
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! :restore_file, @project
  end

  def can_can_access_denied(exception)
    super || redirect_to(file_info_path, alert: exception.message)
  end

  def file_info_path
    # TODO: Redirect to file infos path by file record ID. That is the only
    # =>    stable identifier.
    profile_project_file_infos_path(@project.owner, @project,
                                    file_in_branch.remote_file_id)
  end

  def set_file_version
    @version = VCS::Version.find(params[:id])
  end

  # TODO: Remove after redirecting to file infos path based on file record ID
  def file_in_branch
    @master_branch
      .files.find_by(file_id: @version.file_id)
  end
end
