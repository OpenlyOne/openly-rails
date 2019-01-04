# frozen_string_literal: true

# Controller for project setup
class ProjectSetupsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!, except: :show
  before_action :set_project
  before_action :authorize_project_access
  before_action :authorize_action
  before_action :redirect_to_show_if_setup_started_or_done, only: %i[new create]
  before_action :redirect_to_new_if_setup_not_started,      only: :show
  before_action :redirect_to_project_if_setup_complete,     only: :show
  before_action :build_setup, only: %i[new create]
  before_action :set_setup

  def new; end

  def create
    if @setup.begin(project_setup_params)
      redirect_to profile_project_setup_path(@project.owner, @project),
                  notice: 'Files are being imported...'
    else
      render :new
    end
  end

  def show; end

  private

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! :setup, @project
  end

  def build_setup
    @project.build_setup
  end

  def can_can_access_denied(exception)
    super || redirect_to(profile_project_path(@project.owner, @project),
                         alert: exception.message)
  end

  def project_setup_params
    params.require(:project_setup).permit(:link)
  end

  def redirect_to_show_if_setup_started_or_done
    return if @project.setup_not_started?

    redirect_to(profile_project_setup_path(@project.owner, @project),
                notice: 'Files are already being imported...')
  end

  def redirect_to_new_if_setup_not_started
    return unless @project.setup_not_started?

    redirect_to(new_profile_project_setup_path(@project.owner, @project))
  end

  def redirect_to_project_if_setup_complete
    return unless @project.setup_completed?

    redirect_to(profile_project_path(@project.owner, @project),
                notice: 'Setup has been completed.')
  end

  def set_setup
    @setup = @project.setup
  end
end
