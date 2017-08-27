# frozen_string_literal: true

# Controller for project files
class FilesController < ApplicationController
  before_action :authenticate_account!, except: :show
  before_action :set_file, only: %i[show edit_content update_content]
  before_action :authorize_action, except: :show

  def show; end

  def edit_content; end

  def update_content
    if @file.update(file_params(:content))
      redirect_to [@project.owner, @project, @file],
                  notice: 'File successfully updated.'
    else
      render :edit_content
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to [@project.owner, @project, @file],
                alert: exception.message
  end

  def authorize_action
    authorize! params[:action].to_sym, @file, @project
  end

  def set_file
    @project = Project.find(params[:profile_handle], params[:project_slug])
    @file = @project.files.find params[:name]
  end

  def file_params(permitted_attributes = [])
    params.require(:version_control_file)
          .permit(*permitted_attributes, :revision_summary)
          .merge(revision_author: current_user)
  end
end
