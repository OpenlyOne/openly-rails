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
    FileResource::Thumbnail.preload_for(@children)
  end

  def set_ancestors
    @ancestors = @folder&.ancestors_in_project.to_a
  end

  def set_children
    @children = @folder.children_as_diffs
  end

  def set_folder_from_param
    @folder = Stage::FileDiff.find_by!(external_id: params[:id],
                                       project: @project)

    raise ActiveRecord::RecordNotFound unless @folder.folder?
  end

  def set_folder_from_root
    raise ActiveRecord::RecordNotFound unless @project.root_folder.present?

    @folder = Stage::FileDiff.new(file_resource_id: @project.root_folder.id,
                                  project: @project)
  end

  def set_user_can_commit_changes
    @user_can_commit_changes = can?(:new, :revision, @project)
  end
end
