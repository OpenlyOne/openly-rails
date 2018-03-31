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
    @revisions =
      @project
      .revisions
      .order(id: :desc)
      .includes(:author)
      .preload_file_diffs_with_snapshots
  end

  def new; end

  def create
    if @revision.update(title: revision_params[:title],
                        summary: revision_params[:summary],
                        is_published: true)
      redirect_with_success_to(
        profile_project_root_folder_path(@project.owner, @project)
      )
    else
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
    revision = @project.revisions.create_draft_and_commit_files!(current_user)
    find_revision_by_id(revision.id)
  end

  def can_can_access_denied(exception)
    super || redirect_to([@project.owner, @project], alert: exception.message)
  end

  def find_revision
    find_revision_by_id(revision_params[:id])
  end

  def find_revision_by_id(id)
    @revision =
      Revision.preload_file_diffs_with_snapshots
              .find_by!(id: id, project: @project, author: current_user)
  end

  def revision_params
    params.require(:revision).permit(:title, :summary, :id)
  end
end
