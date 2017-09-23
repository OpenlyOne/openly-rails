# frozen_string_literal: true

# Controller for discussions (suggestions, issues, questions)
class DiscussionsController < ApplicationController
  before_action :authenticate_account!
  before_action :set_project
  before_action :set_discussion_type
  before_action :build_discussion, only: %i[new create]

  def new; end

  def create
    if @discussion.update(discussion_params)
      redirect_with_success_to(
        new_profile_project_discussion_path(@project.owner, @project,
                                            'suggestions'),
        resource: @discussion_type.titleize
      )
    else
      render :new
    end
  end

  private

  def build_discussion
    @discussion =
      Object.const_get("Discussions::#{@discussion_type.titleize}").new(
        initiator: current_user,
        project: @project
      )
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
