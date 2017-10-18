# frozen_string_literal: true

# Controller for project files
class FilesController < ApplicationController
  before_action :authenticate_account!, except: %i[index show]
  before_action :set_project
  before_action :build_file, only: %i[new create]
  before_action :set_file, except: %i[index new create]
  before_action :authorize_action, except: %i[index show]

  def index
    # sort files in alphabetical order (case insensitive) but always put
    # Overview file first
    @files = @project
             .files
             .preload_last_contribution
             .sort_by { |f| [f.name == 'Overview' ? 0 : 1, f.name.downcase] }
    @user_can_add_file = can? :new, @project.files.build, @project
  end

  def new; end

  def create
    if @file.update(file_params(%i[content name]))
      @project.reset_files_count!
      redirect_with_success_to [@project.owner, @project, @file]
    else
      render :new
    end
  end

  def show; end

  def edit_content; end

  def update_content
    if @file.update(file_params(:content))
      redirect_with_success_to [@project.owner, @project, @file]
    else
      render :edit_content
    end
  end

  def edit_name; end

  def update_name
    if @file.update(file_params(:name))
      redirect_with_success_to [@project.owner, @project, @file]
    else
      render :edit_name
    end
  end

  def delete; end

  def destroy
    @file.revision_author   = current_user
    @file.revision_summary  = params[:version_control_file][:revision_summary]
    if @file.destroy
      @project.reset_files_count!
      redirect_with_success_to(
        profile_project_files_path(@project.owner, @project)
      )
    else
      render :delete
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

  def build_file
    @file = @project.files.build
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
