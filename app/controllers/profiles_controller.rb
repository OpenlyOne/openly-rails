# frozen_string_literal: true

# Controller for profiles, such as users
class ProfilesController < ApplicationController
  before_action :authenticate_account!, except: :show
  before_action :set_profile
  before_action :set_color_scheme
  before_action :authorize_action, except: :show

  def show
    @projects =
      Project
      .with_permission_level(current_user)
      .where_profile_is_owner_or_collaborator(@profile)
      .includes(:owner, :master_branch)
      .order(captured_at: :desc)
    @user_can_edit_profile = can?(:edit, @profile)
  end

  def edit; end

  def update
    if @profile.update(profile_params)
      redirect_with_success_to profile_path(@profile)
    else
      render :edit
    end
  end

  private

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to profile_path(@profile), alert: exception.message
  end

  def authorize_action
    authorize! params[:action].to_sym, @profile
  end

  def set_color_scheme
    @color_scheme = @profile.color_scheme
  end

  def set_profile
    @profile = Profiles::Base.find_by!(handle: params[:handle])
  end

  def profile_params
    params.require(:profiles_base).permit(:name, :picture, :about)
  end
end
