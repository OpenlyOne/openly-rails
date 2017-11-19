# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  def show
    @profile = Profiles::Base.find_by!(handle: params[:handle])
    @projects = @profile.projects.order id: :desc
  end
end
