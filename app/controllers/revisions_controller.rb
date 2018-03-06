# frozen_string_literal: true

# Controller for project revisions
class RevisionsController < ApplicationController
  before_action :authenticate_account!, except: :index
  before_action :set_project
  before_action :authorize_action, except: :index
  before_action :build_revision, only: :new
  before_action :find_revision, only: :create
  before_action :set_file_diffs, only: :new
  # TODO: Find way to not manually set provider for all file diffs while still
  #       avoiding N+1 query
  before_action :set_provider_for_file_diffs, only: :new
  # TODO: Sort children in query, not manually afterwards
  before_action :sort_file_diffs, only: :new

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
    redirect_to [@project.owner, @project], alert: exception.message
  end

  def authorize_action
    authorize! params[:action].to_sym, :revision, @project
  end

  def build_revision
    @revision = @project.revisions.create_draft_and_commit_files!(current_user)
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

  def sort_file_diffs
    helpers.sort_file_diffs!(@file_diffs)
  end

  def set_provider_for_file_diffs
    @file_diffs.each do |diff|
      diff.provider = @project.root_folder.provider
    end
  end

  # Find and set project. Raise 404 if project does not exist
  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def revision_params
    params.require(:revision).permit(:title, :summary, :id)
  end
end
