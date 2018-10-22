# frozen_string_literal: true

class Revision
  # File browsing actions for a project revision
  class FoldersController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_revision, only: %i[root]
    before_action :set_folder, only: %i[root]
    before_action :set_children, only: %i[root]
    before_action :preload_backups_for_children, only: %i[root]

    def root
      render 'show'
    end

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

    def set_folder
      @folder = @project.root_folder
    end

    def set_revision
      @revision = @project.revisions.find(params[:revision_id])
    end
  end
end
