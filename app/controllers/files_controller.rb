# frozen_string_literal: true

# Controller for project files
class FilesController < ApplicationController
  before_action :set_file, only: %i[show]

  def show; end

  private

  def set_file
    @project = Project.find(params[:profile_handle], params[:project_slug])
    @file = @project.files.find params[:name]
  end
end
