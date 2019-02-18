# frozen_string_literal: true

# Controller for project contributions
class ContributionsController < ApplicationController
  include CanSetProjectContext

  before_action :authenticate_account!, except: %i[index show]
  before_action :set_project_where_setup_is_complete
  before_action :authorize_project_access
  before_action :build_contribution, only: %i[new create]
  before_action :authorize_action, only: %i[new create]
  before_action :find_contribution, only: :show

  def index
    @contributions = @project.contributions.order(id: :desc).includes(:creator)
  end

  def new; end

  def create
    if @contribution.setup(contribution_params)
      redirect_with_success_to(
        profile_project_contribution_path(
          @project.owner, @project, @contribution
        )
      )
    else
      render :new
    end
  end

  def show; end

  private

  rescue_from CanCan::AccessDenied do |exception|
    can_can_access_denied(exception)
  end

  def authorize_action
    authorize! params[:action].to_sym, @contribution
  end

  def build_contribution
    @contribution = @project.contributions.build(
      creator: current_user,
      origin_revision: @project.revisions.last
    )
  end

  def find_contribution
    @contribution = @project.contributions.find(params[:id])
  end

  def can_can_access_denied(exception)
    super || redirect_to(
      profile_project_contributions_path(@project.owner, @project),
      alert: exception.message
    )
  end

  def contribution_params
    params.require(:contribution).permit(:title, :description)
  end
end
