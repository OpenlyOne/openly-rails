# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!, except: :show
  before_action :build_project, only: %i[new create]
  before_action :set_project, only: %i[show edit update destroy]
  before_action :authorize_action, only: %i[edit update destroy]
  before_action :authorize_project_access, only: :show

  def new; end

  def create
    if @project.update(project_params)
      redirect_with_success_to(
        new_profile_project_setup_path(@project.owner, @project)
      )
    else
      render :new
    end
  end

  def show
    redirect_to profile_project_overview_path(@project.owner, @project)
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
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! params[:action].to_sym, @project
  end

  def build_project
    @project = current_user.projects.build
  end

  def can_can_access_denied(exception)
    super || redirect_to([@project.owner, @project], alert: exception.message)
  end

  def profile_slug
    params[:slug]
  end

  def project_params
    params.require(:project).permit(:title, :slug, :tag_list, :description)
  end
end
