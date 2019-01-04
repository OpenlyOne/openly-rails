# frozen_string_literal: true

module Admin
  module Profiles
    # Administration controller for managing users
    class UsersController < Admin::ApplicationController
      private

      # Do not allow creation of new users. Create a new account instead.
      def show_action?(action, _resource)
        action.to_sym != :new
      end

      # Manually set resource class, otherwise Administrate defaults to
      # Profile::User
      def resource_class
        ActiveSupport::Inflector.constantize('Profiles::User')
      end

      # Manually set dashboard class, otherwise Administrate defaults to
      # Profile::UserDashboard
      def dashboard_class
        ActiveSupport::Inflector.constantize("#{resource_class}Dashboard")
      end
    end
  end
end
