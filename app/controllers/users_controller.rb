# frozen_string_literal: true

# Controller for user (profile)
class UsersController < ApplicationController
  def show
    @user = User.find params[:id]
  end
end
