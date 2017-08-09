# frozen_string_literal: true

# Controller for projects
class ProjectsController < ApplicationController
  before_action :set_project

  def show; end

  private

  def set_project
    @project = Project.find(params[:profile_handle], params[:slug])
  end
end
