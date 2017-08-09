# frozen_string_literal: true

# Profile class handles all types of profiles, such as users and teams.
class Profile
  def self.find(handle)
    # This works but does not eager load handle, meaning it is loaded twice
    Handle.find_by_identifier!(handle).profile

    # This eager loads the handle but creates a more complex SQL query
    # User
    #   .includes(:handle)
    #   .joins(:handle)
    #   .find_by!(handles: { identifier: handle })
  end
end
