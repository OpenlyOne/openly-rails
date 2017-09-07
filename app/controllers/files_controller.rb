# frozen_string_literal: true

# Controller for project files
class FilesController < ApplicationController
  before_action :authenticate_account!, except: %i[index show]
  before_action :set_project
  before_action :set_file, except: :index
  before_action :authorize_action, except: %i[index show]

  def index
    # sort files in alphabetical order (case insensitive) but always put
    # Overview file first
    @files = @project
             .files
             .sort_by { |f| [f.name == 'Overview' ? 0 : 1, f.name.downcase] }
  end

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

  def edit_name; end

  def update_name
    if @file.update(file_params(:name))
      redirect_to [@project.owner, @project, @file],
                  notice: 'File successfully updated.'
    else
      render :edit_name
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

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def set_file
    @file = @project.files.find params[:name]
  end

  def file_params(permitted_attributes = [])
    params.require(:version_control_file)
          .permit(*permitted_attributes, :revision_summary)
          .merge(revision_author: current_user)
  end
end
