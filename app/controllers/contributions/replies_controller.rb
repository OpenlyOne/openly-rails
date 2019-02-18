# frozen_string_literal: true

module Contributions
  # Controller for replies to contributions
  class RepliesController < ApplicationController
    include CanSetProjectContext

    before_action :set_project_where_setup_is_complete
    before_action :authorize_project_access
    before_action :find_contribution
    before_action :set_replies

    def index; end

    private

    def find_contribution
      @contribution = @project.contributions.find(params[:contribution_id])
    end

    def set_replies
      @replies = @contribution.replies.includes(:author)
    end
  end
end
