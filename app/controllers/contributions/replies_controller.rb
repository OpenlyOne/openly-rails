# frozen_string_literal: true

module Contributions
  # Controller for replies to contributions
  class RepliesController < ApplicationController
    include CanSetProjectContext

    before_action :authenticate_account!, except: :index
    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :find_contribution
    before_action :authorize_action, except: :index
    before_action :set_replies, only: :index
    before_action :build_reply
    before_action :set_user_can_reply_to_contribution, only: :index

    def index; end

    def create
      if @reply.update(reply_params)
        redirect_with_success_to(contribution_replies_path)
      else
        set_replies
        set_user_can_reply_to_contribution
        render 'index'
      end
    end

    private

    rescue_from CanCan::AccessDenied do |exception|
      can_can_access_denied(exception)
    end

    def authorize_action
      authorize! :reply, @contribution
    end

    def can_can_access_denied(exception)
      super || redirect_to(contribution_replies_path, alert: exception.message)
    end

    def build_reply
      @reply = @contribution.replies.build(author: current_user)
    end

    def contribution_replies_path
      profile_project_contribution_replies_path(
        @project.owner, @project, @contribution
      )
    end

    def find_contribution
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    def set_replies
      @replies = @contribution.replies.includes(:author)
    end

    def set_user_can_reply_to_contribution
      @user_can_reply_to_contribution = can?(:reply, @contribution)
    end

    def reply_params
      params.require(:reply).permit(:content)
    end
  end
end
