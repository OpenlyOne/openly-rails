# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  include ProjectLockable

  # Execute without lock or render/redirect delay
  before_action :set_project

  around_action :wrap_action_in_project_lock

  # Execute with lock and render/redirect delay
  before_action :set_folder
  before_action :set_root_folder
  before_action :set_ancestors
  before_action :set_user_can_commit_changes
  before_action :set_files

  def root
    render 'show'
  end

  def show; end

  private

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def set_folder
    # If id is not set, we want to load the root folder
    params[:id] ||= @project.files.root_id

    # Load the folder
    @folder = @project.files.find_by_id(params[:id])

    # Raise error unless folder is a directory
    raise ActiveRecord::RecordNotFound unless @folder&.directory?
  end

  def set_files
    @files = @folder.children

    helpers.sort_files!(@files)
  end

  def set_root_folder
    @root_folder = @project.files.root
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end

  def set_ancestors
    @ancestors = @folder.ancestors
  end
end
