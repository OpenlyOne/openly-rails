# frozen_string_literal: true

module Revisions
  # Controller for project revision file infos
  class FileChangesController < Abstract::FileChangesController
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

    # Set the file diff found within the revision
    def set_file_diff
      @file_diff = @revision.file_diffs.find_by_hashed_file_id!(params[:id])
    end

    def set_branch
      @branch = @master_branch
    end

    def set_object
      @revision = @project.revisions.find(params[:revision_id])
    end
  end
end
