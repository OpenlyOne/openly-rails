# frozen_string_literal: true

module Abstract
  # Abstract super class for force syncs controller used for project and
  # contributions
  class ForceSyncsController < ApplicationController
    include CanSetProjectContext

    before_action :authenticate_account!
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :set_object
    before_action :set_branch
    before_action :authorize_action
    before_action :set_file_in_branch

    def create
      @file.pull(force_sync: true)
      # TODO: Add feature spec to test this!
      @file.pull_children if @file.folder_now_or_before_last_save?

      redirect_to file_info_path, notice: 'File successfully synced.'
    end

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def can_can_access_denied(exception)
      super || redirect_to(file_info_path, alert: exception.message)
    end

    # Set the file in branch
    def set_file_in_branch
      @file = @branch.files.without_root.find_by_hashed_file_id!(params[:id])
    end

    # Overwrite to set an object from params, such as a contribution
    def set_object; end
  end
end
