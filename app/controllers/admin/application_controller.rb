# frozen_string_literal: true

# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  # Administration controller parent
  class ApplicationController < Administrate::ApplicationController
    before_action :authenticate_admin

    private

    def authenticate_admin
      authenticate_account!
      authorize! :manage, :admin_panel
    end

    # Get the current user
    def current_user
      current_account.try(:user)
    end
  end
end
