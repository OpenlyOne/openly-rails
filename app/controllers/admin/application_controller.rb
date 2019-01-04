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

    # HACK: Overwrite #redirect_to, so that we can force-pass ID
    # =>    This is necessary because the Project resource uses a
    # =>    non-identifying #to_param method. A project's slug alone is not
    # =>    sufficient to identify it. Routes in administrate are generated
    # =>    using the polymorphic_path helper which - by default - relies on
    # =>    the #to_param method. By explicitly passing the id: and format:
    # =>    parameters, we can overwrite this behavior.
    def redirect_to(path, options = {})
      # Force pass id and format parameters if the path is an array of objects
      path.push(id: path.last.id, format: nil) if path.is_a?(Array)

      # Simply pass everything forward
      super(path, options)
    end

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
