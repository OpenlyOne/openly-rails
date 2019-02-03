# frozen_string_literal: true

module Abstract
  # Abstract super class for folders controller used for project and
  # contributions
  class FoldersController < ApplicationController
    include CanSetProjectContext

    before_action :authenticate_account!, :require_authentication?
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :authorize_action
    before_action :set_object
    before_action :set_branch
    before_action :set_folder_from_param, only: :show
    before_action :set_folder_from_root, only: :root
    before_action :set_children
    before_action :preload_thumbnails_for_children
    before_action :set_ancestors
    before_action :set_user_can_commit_changes

    def root
      render_folders_show
    end

    def show
      render_folders_show
    end

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def authorize_action
      # Overwrite to authorize the action
    end

    def render_folders_show
      render 'folders/show', locals: {
        path_parameters: path_parameters,
        folder_path: "#{link_path_prefix}folder_path",
        file_infos_path: "#{link_path_prefix}file_infos_path",
        root_folder_path: "#{link_path_prefix}root_folder_path"
      }
    end

    # TODO: Do we still need this method?
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
        @branch
        .folders
        .find_by_hashed_file_id_or_remote_file_id!(params[:id])

      raise ActiveRecord::RecordNotFound unless @folder&.version&.folder?
    end

    def set_folder_from_root
      raise ActiveRecord::RecordNotFound unless @branch.root.present?

      @folder = @branch.root
    end

    # Can the current user capture changes? Defaults to false
    def set_user_can_commit_changes
      @user_can_commit_changes = false
    end

    # @abstract Subclass is expected to implement #set_object
    # @!method set_object
    #   Load the object here, such as the contribution

    # @abstract Subclass is expected to implement #set_branch
    # @!method set_branch
    #   Set the branch here, such as @master_branch or contribution.branch
  end
end
