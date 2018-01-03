# frozen_string_literal: true

# Controller for project revisions
class RevisionsController < ApplicationController
  include ProjectLockable

  # Execute without lock or render/redirect delay
  before_action :authenticate_account!
  before_action :set_project
  before_action :authorize_action

  around_action :wrap_action_in_project_lock

  # Execute with lock and render/redirect delay
  before_action :build_revision
  before_action :set_root_folder

  def new; end

  def create
    if @revision.commit(revision_params[:summary], revision_author)
      redirect_with_success_to(
        profile_project_root_folder_path(@project.owner, @project)
      )
    else
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
    tree_id = revision_params[:tree_id] if params[:revision]
    @revision = @project.repository.build_revision(tree_id)
  end

  def revision_author
    # current_user.to_revision_author
    { name: current_user.handle, email: current_user.id.to_s }
  end

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def set_root_folder
    @root_folder = @project.files.root
  end

  def revision_params
    params.require(:revision).permit(:summary, :tree_id)
  end
end
