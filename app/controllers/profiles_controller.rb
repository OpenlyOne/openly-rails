# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  def show
    @profile = Handle.find_by_identifier!(params[:handle]).profile
  end
end
