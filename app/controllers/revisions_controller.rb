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
  before_action :set_file_diffs, only: :new

  def index
    # TODO: Raise 404 if no revisions exist or redirect
    @revisions =
      @project
      .revisions
      .order(id: :desc)
      .includes(:author, file_diffs: %i[current_snapshot previous_snapshot])
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
      set_file_diffs
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
    @revision = @project.revisions.create_draft_and_commit_files!(current_user)
  end

  def can_can_access_denied(exception)
    super || redirect_to([@project.owner, @project], alert: exception.message)
  end

  def find_revision
    @revision = Revision.find_by!(id: revision_params[:id],
                                  project: @project,
                                  author: current_user)
  end

  def set_file_diffs
    @file_diffs =
      @revision.file_diffs.includes(:current_snapshot, :previous_snapshot).to_a
  end

  def revision_params
    params.require(:revision).permit(:title, :summary, :id)
  end
end
