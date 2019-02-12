# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!, except: :show
  before_action :build_project, only: %i[new create]
  before_action :assign_create_params_to_project, only: %i[create]
  before_action :set_project, only: %i[show edit update destroy]
  before_action :authorize_action, only: %i[create edit update destroy]
  before_action :authorize_project_access, only: :show

  def new; end

  def create
    if @project.save
      redirect_with_success_to(
        new_profile_project_setup_path(@project.owner, @project)
      )
    else
      render :new
    end
  end

  # Re-route user depending on whether they have permission to collaborate on
  # the project:
  # - Non-Collaborators are redirected to the overview page
  # - Collaborators are redirected to setup/files
  def show
    return redirect_to project_overview_path unless can?(:collaborate, @project)

    # User is a collaborator, determine the correct destination for redirection
    if @project.setup_not_started?
      redirect_to new_profile_project_setup_path(@project.owner, @project)
    elsif @project.setup_in_progress?
      redirect_to profile_project_setup_path(@project.owner, @project)
    else
      redirect_to profile_project_root_folder_path(@project.owner, @project)
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_with_success_to project_overview_path
    else
      render :edit
    end
  end

  def destroy
    if @project.destroy
      redirect_with_success_to profile_path(@project.owner)
    else
      redirect_to project_overview_path,
                  alert: 'An unexpected error occured while deleting the ' \
                         'project.'
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    case action_name.to_sym
    when :create
      raise StandardError, 'Unauthorized to create private project'
    else
      can_can_access_denied(exception)
    end
  end

  def authorize_action
    authorize! params[:action].to_sym, @project
  end

  def assign_create_params_to_project
    @project.assign_attributes(project_create_params)
  end

  def build_project
    @project = current_user.projects.build
  end

  def can_can_access_denied(exception)
    super || redirect_to(project_overview_path, alert: exception.message)
  end

  def profile_slug
    params[:slug]
  end

  def project_create_params
    params
      .require(:project)
      .permit(:title, :slug, :tag_list, :description, :is_public)
  end

  def project_params
    params
      .require(:project)
      .permit(:title, :slug, :tag_list, :description)
  end

  def project_overview_path
    profile_project_overview_path(@project.owner, @project)
  end
end
