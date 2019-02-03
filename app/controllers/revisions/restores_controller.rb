# frozen_string_literal: true

module Revisions
  # File browsing actions for a project revision
  class RestoresController < ApplicationController
    include CanSetProjectContext

    before_action :set_revision, only: :create
    before_action :authenticate_account!
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :authorize_action

    def create
      @master_branch.restore_commit(@revision, author: current_user)

      redirect_to(
        restore_status_profile_project_revisions_path(@project.owner, @project),
        notice: 'Revision is being restored...'
      )
    end

    def show
      @file_restores_remaining =
        Delayed::Job
        .where(queue: :file_restore, delayed_reference_id: @master_branch.id)
        .count

      # Show status page if file restores are remaining
      return unless @file_restores_remaining.zero?

      redirect_to(root_folder_path, notice: 'Revision successfully restored.')
    end

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def authorize_action
      authorize! :restore_revision, @project
    end

    def can_can_access_denied(exception)
      super || redirect_to(project_revisions_path, alert: exception.message)
    end

    def root_folder_path
      profile_project_root_folder_path(@project.owner, @project)
    end

    def project_revisions_path
      profile_project_revisions_path(@project.owner, @project)
    end

    def set_revision
      @revision = VCS::Commit.find(params[:revision_id])
    end
  end
end
