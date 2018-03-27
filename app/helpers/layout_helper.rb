# frozen_string_literal: true

# Define helpers needed in layout files
module LayoutHelper
  # Return a string containing controller and action name, formatted as
  # 'c-controller_name a-action_name'
  def controller_action_identifier
    "c-#{controller_name} a-#{action_name}".tr('_', '-')
  end

  # Pick random color scheme
  def color_scheme
    scheme = Color.schemes.sample
    "color-scheme primary-#{scheme[:base]} primary-#{scheme[:text]}-text"
  end

  # Used to achieve nested layouts without content_for. This helper relies on
  # Rails internals, so beware that it make break with future major versions
  # of Rails. Inspired by http://stackoverflow.com/a/18214036
  #
  # Usage: For example, suppose "child" layout extends "parent" layout.
  # Use <%= yield %> as you would with non-nested layouts, as usual. Then on
  # the very last line of layouts/child.html.erb, include this:
  #
  #     <% parent_layout "parent" %>
  #
  # Credits: https://gist.github.com/mattbrictson/9240548
  def parent_layout(layout)
    @view_flow.set :layout, output_buffer
    output = render(file: "layouts/#{layout}")
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end
end
