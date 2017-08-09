# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  def show
    @profile = Profile.find params[:handle]
    @projects = @profile.projects.order id: :desc
  end
end
