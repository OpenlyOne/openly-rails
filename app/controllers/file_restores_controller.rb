class FileRestoresController < ApplicationController
  include CanSetProjectContext

  before_action :set_file_snapshot
  before_action :authenticate_account!
  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :authorize_action

  def create
    VCS::Operations::FileRestore.new(
      snapshot: @snapshot,
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
    profile_project_file_infos_path(@project.owner, @project,
                                    @snapshot.external_id)
  end

  def set_file_snapshot
    @snapshot = VCS::FileSnapshot.find(params[:id])
  end
end
