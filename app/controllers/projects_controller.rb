# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  before_action :authenticate_account!, except: :show
  before_action :build_project, only: %i[new create]
  before_action :set_project, only: %i[show edit update destroy]
  before_action :authorize_action, only: %i[edit update destroy]

  def new; end

  def create
    if @project.update(project_params)
      redirect_to [@project.owner, @project],
                  notice: 'Project successfully created.'
    else
      render :new
    end
  end

  def show
    @user_can_edit_project  = can?(:edit, @project)
    @overview               = @project.files.find 'Overview'
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to [@project.owner, @project],
                  notice: 'Project successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @project.destroy
    redirect_to [@project.owner], notice: 'Project successfully deleted.'
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
    params.require(:project).permit(:title, :slug)
  end
end
