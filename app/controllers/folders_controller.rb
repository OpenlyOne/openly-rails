# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  include CanSetProjectContext

  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :set_folder_from_param, only: :show
  before_action :set_folder_from_root, only: :root
  before_action :set_children
  before_action :preload_thumbnails_for_children
  before_action :set_ancestors
  before_action :set_user_can_commit_changes

  def root
    render 'show'
  end

  def show; end

  private

  def preload_thumbnails_for_children
    # FileResource::Thumbnail.preload_for(@children)
  end

  def set_ancestors
    @ancestors = @folder.ancestors.to_a
  end

  def set_children
    @children = @folder.children.order_by_name_with_folders_first
  end

  def set_folder_from_param
    @folder = @master_branch.staged_folders.find_by_external_id(params[:id])

    raise ActiveRecord::RecordNotFound unless @folder.staged_snapshot.folder?
  end

  def set_folder_from_root
    raise ActiveRecord::RecordNotFound unless @master_branch.root.present?

    @folder = @master_branch.root
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end
end
