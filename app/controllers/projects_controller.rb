# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  before_action :authenticate_account!, except: :show
  before_action :build_project, only: %i[new create]
  before_action :set_project, only: %i[show]

  def new; end

  def create
    if @project.update(project_params)
      redirect_to [@project.owner, @project],
                  notice: 'Project successfully created.'
    else
      render :new
    end
  end

  def show; end

  private

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
