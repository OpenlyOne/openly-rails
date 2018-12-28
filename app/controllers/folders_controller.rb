# frozen_string_literal: true

# Controller for project folders
class FoldersController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!
  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :authorize_action
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

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! :show, :file_in_branch, @project
  end

  def can_can_access_denied(exception)
    super || redirect_to(project_path, alert: exception.message)
  end

  def project_path
    profile_project_path(@project.owner, @project)
  end

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
    @folder =
      @master_branch
      .folders
      .find_by_hashed_file_id_or_remote_file_id!(params[:id])

    raise ActiveRecord::RecordNotFound unless @folder&.version&.folder?
  end

  def set_folder_from_root
    raise ActiveRecord::RecordNotFound unless @master_branch.root.present?

    @folder = @master_branch.root
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end
end
