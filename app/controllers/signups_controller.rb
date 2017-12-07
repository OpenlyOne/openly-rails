# frozen_string_literal: true

# Controller for all static pages: index, about, contact, etc...
class SignupsController < ApplicationController

  layout false

  def create
    Signup.create(signup_params)
  end

  private

  def signup_params
    params.require(:signup).permit(:email)
  end
end
