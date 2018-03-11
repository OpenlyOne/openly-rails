# frozen_string_literal: true

# Controller for project setup
class ProjectSetupsController < ApplicationController
  include CanSetProjectContext

  before_action :set_project
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

  def build_setup
    @project.build_setup
  end

  def project_setup_params
    params.require(:project_setup).permit(:link)
  end

  def set_setup
    @setup = @project.setup
  end
end
