# frozen_string_literal: true

# Controller for replies to discussions (suggestions, issues, questions)
class RepliesController < ApplicationController
  before_action :authenticate_account!, except: %i[index]
  before_action :set_project, except: :index
  before_action :set_discussion, except: :index
  before_action :build_reply, only: :create

  layout 'discussions'

  def index
    redirect_to(controller:       'discussions',
                action:           'show',
                profile_handle:   params[:profile_handle],
                project_slug:     params[:project_slug],
                discussion_type:  params[:discussion_type],
                scoped_id:        params[:discussion_scoped_id])
  end

  def create
    if @reply.update(reply_params)
      redirect_with_success_to(
        profile_project_discussion_path(@project.owner, @project,
                                        @discussion.type_to_url_segment,
                                        @discussion)
      )
    else
      @replies = @discussion.replies.includes(:author)
      render :show
    end
  end

  private

  def build_reply
    @reply = @discussion.replies.build(author: current_user)
  end

  def set_discussion
    @discussion =
      Discussions::Base.find_by!(project: @project,
                                 scoped_id: params[:discussion_scoped_id])
  end

  def set_project
    @project = Project.find(params[:profile_handle], params[:project_slug])
  end

  def reply_params
    params.require('reply').permit(:content)
  end
end
