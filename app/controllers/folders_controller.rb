# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  before_action :set_project
  before_action :set_variables_under_repository_lock

  def root
    render 'show'
  end

  def show; end

  private

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  # Sets various controller instance variables under repository lock to ensure
  # that variables are loaded in a concurrency-safe way.
  def set_variables_under_repository_lock
    @project.repository.lock do
      set_folder
      @root_folder = @project.files.root
      @ancestors   = @folder.ancestors
      set_files
    end
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
end
