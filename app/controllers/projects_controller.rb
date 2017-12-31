# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  include ProjectLockable

  # Execute without lock or render/redirect delay
  before_action :authenticate_account!, except: :show
  before_action :build_project, only: %i[new create]
  before_action :set_project, only: %i[setup import show edit update destroy]
  before_action :authorize_action, only: %i[setup import edit update destroy]

  around_action :wrap_action_in_project_lock, only: :show

  def new; end

  def create
    if @project.update(project_params)
      redirect_with_success_to(
        setup_profile_project_path(@project.owner, @project)
      )
    else
      render :new
    end
  end

  def setup
    return if @project.files.root.nil?

    # Redirect to project page if set up has been completed
    redirect_to [@project.owner, @project],
                notice: 'Project has already been set up.'
  end

  def import
    @project.import_google_drive_folder_on_save = true
    if @project.update(project_params)
      redirect_with_success_to [@project.owner, @project],
                               resource: 'Google Drive folder'
    else
      render :setup
    end
  end

  def show
    @root_folder = @project.files.root
    @user_can_edit_project = can?(:edit, @project)
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_with_success_to [@project.owner, @project]
    else
      render :edit
    end
  end

  def destroy
    if @project.destroy
      redirect_with_success_to [@project.owner]
    else
      redirect_to [@project.owner, @project],
                  alert: 'An unexpected error occured while deleting the ' \
                         'project.'
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to [@project.owner, @project], alert: exception.message
  end

  def authorize_action
    authorize! params[:action].to_sym, @project
  end

  def build_project
    @project = current_user.projects.build
  end

  def set_project
    @project = Project.find(params[:profile_handle], params[:slug])
  end

  def project_params
    attributes =
      case action_name.to_sym
      when :create
        %w[title]
      when :import
        %w[link_to_google_drive_folder]
      else
        %w[title slug]
      end

    params.require(:project).permit(*attributes)
  end
end
