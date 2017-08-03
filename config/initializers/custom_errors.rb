# frozen_string_literal: true

# Modified from https://gist.github.com/t2/1464315
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  input_elements = %w[textarea input select]

  html = Nokogiri::HTML::DocumentFragment.parse(html_tag)

  # find all input elements within the html snippet and add class 'invalid'
  html.css(input_elements.join(', ')).each do |input|
    input['class'] = input['class'].to_s + ' invalid'
  end

  html.to_html.html_safe
end
