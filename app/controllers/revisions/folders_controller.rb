# frozen_string_literal: true

module Revisions
  # File browsing actions for a project revision
  class FoldersController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_revision, only: %i[root show]
    before_action :set_folder_from_root, only: :root
    before_action :set_folder_from_param, only: :show
    before_action :set_children, only: %i[root show]
    before_action :set_ancestors, only: %i[root show]

    def root
      render 'show'
    end

    def show; end

    private

    # TODO: Refactor into ancestry generator class
    def set_ancestors
      @ancestors = []
      ancestor =
        @revision.committed_versions
                 .find_by(file_id: @folder.parent_id)

      while ancestor.present?
        @ancestors << ancestor
        ancestor =
          @revision.committed_versions
                   .find_by(file_id: ancestor.parent_id)
      end
    end

    def set_children
      @children =
        @revision.committed_versions
                 .includes(:backup, :thumbnail)
                 .where(parent_id: @folder.file_id)
                 .order_by_name_with_folders_first
    end

    def set_folder_from_param
      @folder =
        @revision
        .committed_versions
        .find_by!(remote_file_id: params[:id])

      # TODO: Don't check if file resource is folder NOW, check if committed
      # =>    file resource version was folder BACK at commit
      raise ActiveRecord::RecordNotFound unless @folder.folder?
    end

    def set_folder_from_root
      @folder = VCS::Version.new(file: @master_branch.root.file)
    end

    def set_revision
      @revision = @master_branch.commits.find(params[:revision_id])
    end
  end
end
