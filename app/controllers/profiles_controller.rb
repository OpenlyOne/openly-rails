# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  before_action :authenticate_account!, except: :show
  before_action :set_profile
  before_action :authorize_action, except: :show

  def show
    @projects = @profile.projects.order id: :desc
    @user_can_edit_profile = can?(:edit, @profile)
  end

  def edit; end

  def update
    if @profile.update(profile_params)
      redirect_with_success_to @profile
    else
      render :edit
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to @profile, alert: exception.message
  end

  def authorize_action
    authorize! params[:action].to_sym, @profile
  end

  def set_profile
    @profile = Profiles::Base.find_by!(handle: params[:handle])
  end

  def profile_params
    params.require(:profiles_base).permit(:name, :picture)
  end
end
