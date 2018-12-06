# frozen_string_literal: true

module Revisions
  # Controller for project revision file infos
  class FileChangesController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_revision
    before_action :set_file_diff
    before_action :ensure_modification
    before_action :ensure_content_change

    def show
      render 'file_changes/show'
    end

    private

    # Raise error unless we have a modification
    def ensure_modification
      return if @file_diff.modification?

      raise ActiveRecord::RecordNotFound
    end

    # Raise error unless we have content change
    def ensure_content_change
      return if @file_diff.content_change.present?

      raise ActiveRecord::RecordNotFound
    end

    # Set the uncaptured file diff if file in branch has current or committed
    # version present
    def set_file_diff
      @file_diff = @revision.file_diffs.find_by_hashed_file_id!(params[:id])
    end

    def set_revision
      @revision = @project.revisions.find(params[:revision_id])
    end
  end
end
