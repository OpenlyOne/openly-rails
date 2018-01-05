# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  include ProjectLockable

  # Execute without lock or render/redirect delay
  before_action :set_project

  around_action :wrap_action_in_project_lock

  # Execute with lock and render/redirect delay
  before_action :set_folder_diff
  before_action :set_file_diffs
  before_action :set_ancestors
  before_action :set_root_folder
  before_action :set_user_can_commit_changes

  def root
    render 'show'
  end

  def show; end

  private

  def set_ancestors
    @ancestors = @folder_diff.ancestors_of_file
  end

  def set_file_diffs
    @file_diffs = @folder_diff.children_as_diffs

    helpers.sort_file_diffs!(@file_diffs)
  end

  def set_folder_diff
    # Load the folder. If ID param is not set, load root folder.
    @folder_diff = @project.repository
                           .stage
                           .diff(@project.repository.revisions.last)
                           .diff_file(params[:id] || @project.files.root_id)

    # Raise error if folder is not a directory
    raise ActiveRecord::RecordNotFound unless @folder_diff.directory?
  end

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def set_root_folder
    @root_folder = @project.files.root
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end
end
