# frozen_string_literal: true

# Define helpers needed in layout files
module LayoutHelper
  # Return a string containing controller and action name, formatted as
  # 'c-controller_name a-action_name'
  def controller_action_identifier
    "c-#{controller_name} a-#{action_name}"
  end

  # Pick random color scheme
  def color_scheme
    scheme = Color.schemes.sample
    "color-scheme primary-#{scheme[:base]} primary-#{scheme[:text]}-text"
  end
end
