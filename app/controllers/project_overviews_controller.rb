# frozen_string_literal: true

# Controller for project overviews
class ProjectOverviewsController < ApplicationController
  include CanSetProjectContext

  before_action :set_project
  before_action :authorize_project_access

  def show
    @collaborators = @project.collaborators.order(:name, :id)
    @user_can_edit_project = can?(:edit, @project)
  end
end
