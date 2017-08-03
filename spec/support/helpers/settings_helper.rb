# frozen_string_literal: true

# Settings helper methods
module SettingsHelper
  def enable_account_registration
    temporary_registration_status true
  end

  def disable_account_registration
    temporary_registration_status false
  end

  # set enable_account_registration to status and reset after completion
  def temporary_registration_status(status)
    before(:context) do
      Settings.enable_account_registration = status
      Rails.application.reload_routes!
    end

    after(:context) do
      Settings.reload!
      Rails.application.reload_routes!
    end
  end
end
