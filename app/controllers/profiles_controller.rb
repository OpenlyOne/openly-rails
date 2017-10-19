# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  def show
    @profile = Profiles::Base.includes(:handle)
                             .find_by!(handles: { identifier: params[:handle] })
    @projects = @profile.projects.order id: :desc
  end
end
