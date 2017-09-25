# frozen_string_literal: true

# Controller for discussions (suggestions, issues, questions)
class DiscussionsController < ApplicationController
  before_action :authenticate_account!, except: %i[index show]
  before_action :set_project
  before_action :set_discussion_type
  before_action :build_discussion, only: %i[new create]
  before_action :set_discussion, except: %i[index new create]
  before_action :redirect_to_path_with_matching_type,
                only: %i[show],
                if: -> { @discussion.type_to_url_segment != params[:type] }

  def index
    @discussions = @project.send(@discussion_type.pluralize.to_sym)
                           .includes(:initiator).all
    @user_can_add_discussion = current_user.present?
  end

  def new; end

  def create
    if @discussion.update(discussion_params)
      redirect_with_success_to(
        profile_project_discussion_path(@project.owner, @project,
                                        @discussion_type.pluralize,
                                        @discussion),
        resource: @discussion_type.titleize
      )
    else
      render :new
    end
  end

  def show; end

  private

  def build_discussion
    @discussion =
      Object.const_get("Discussions::#{@discussion_type.titleize}").new(
        initiator: current_user,
        project: @project
      )
  end

  # redirect to the path with the correct type
  def redirect_to_path_with_matching_type
    redirect_to(controller:     controller_name,
                action:         action_name,
                profile_handle: params[:profile_handle],
                project_slug:   params[:project_slug],
                type:           @discussion.type_to_url_segment,
                scoped_id:      params[:scoped_id])
  end

  def set_discussion
    @discussion = Discussions::Base.find_by!(project: @project,
                                             scoped_id: params[:scoped_id])
  end

  def set_discussion_type
    @discussion_type = params[:type].to_s.singularize
  end

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def discussion_params
    params.require("discussions_#{@discussion_type}").permit(:title)
  end
end
