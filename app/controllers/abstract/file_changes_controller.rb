# frozen_string_literal: true

module Abstract
  # Abstract super class for force syncs controller used for project and
  # contributions
  class FileChangesController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_object
    before_action :set_branch
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
      @file_diff = file_in_branch.diff
    end

    def file_in_branch
      @file_in_branch ||=
        @branch
        .files
        .without_root
        .joins_version
        .find_by_hashed_file_id!(params[:id])
    end

    # Overwrite to set an object from params, such as a contribution
    def set_object; end
  end
end
