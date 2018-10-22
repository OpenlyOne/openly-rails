# frozen_string_literal: true

class Revision
  # File browsing actions for a project revision
  class FoldersController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_revision, only: %i[root show]
    before_action :set_folder_from_root, only: :root
    before_action :set_folder_from_param, only: :show
    before_action :set_children, only: %i[root show]
    before_action :preload_backups_for_children, only: %i[root show]

    def root
      render 'show'
    end

    def show; end

    private

    def preload_backups_for_children
      ActiveRecord::Associations::Preloader.new.preload(
        Array(@children).flat_map(&:file_resource_snapshot),
        backup: :file_resource
      )
    end

    def set_children
      @children =
        @revision.committed_files
                 .includes(file_resource_snapshot: [:file_resource])
                 .in_folder(@folder)
                 .order_by_name_with_folders_first
    end

    def set_folder_from_param
      @folder =
        @revision.committed_files
                 .includes(:file_resource)
                 .find_by!(file_resources: { external_id: params[:id] })
                 .file_resource

      # TODO: Don't check if file resource is folder NOW, check if committed
      # =>    file resource snapshot was folder BACK at commit
      raise ActiveRecord::RecordNotFound unless @folder.folder?
    end

    def set_folder_from_root
      @folder = @project.root_folder
    end

    def set_revision
      @revision = @project.revisions.find(params[:revision_id])
    end
  end
end
