# frozen_string_literal: true

# Controller for project revisions
class RevisionsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!, except: :index
  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :authorize_action, except: :index
  before_action :build_revision, only: :new
  before_action :find_revision, only: :create

  def index
    # TODO: Raise 404 if no revisions exist or redirect
    # TODO: Change variable name from revision to commit
    @revisions =
      @project
      .master_branch
      .commits
      .order(id: :desc)
      .includes(:author)
      .preload_file_diffs_with_snapshots

    preload_backups_for_file_diffs_in_revisions(@revisions)
  end

  def new
    preload_backups_for_file_diffs_in_revisions(@revision)
  end

  def create
    if @revision.publish(revision_params.except('id'))
      redirect_with_success_to(
        profile_project_root_folder_path(@project.owner, @project)
      )
    else
      preload_backups_for_file_diffs_in_revisions(@revision)
      render :new
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! params[:action].to_sym, :revision, @project
  end

  def build_revision
    commit = @master_branch.commits.create_draft_and_commit_files!(current_user)
    find_revision_by_id(commit.id)
  end

  def can_can_access_denied(exception)
    super || redirect_to([@project.owner, @project], alert: exception.message)
  end

  def find_revision
    find_revision_by_id(revision_params[:id])
  end

  def find_revision_by_id(id)
    @revision =
      VCS::Commit
      .preload_file_diffs_with_snapshots
      .find_by!(id: id, branch: @project.master_branch, author: current_user)
  end

  def preload_backups_for_file_diffs_in_revisions(revisions)
    ActiveRecord::Associations::Preloader.new.preload(
      Array(revisions).flat_map(&:file_diffs)
                      .flat_map(&:current_or_previous_snapshot),
      :backup
    )
  end

  def revision_params
    params.require(:revision)
          .permit(:title, :summary, :id, selected_file_change_ids: [])
  end
end
