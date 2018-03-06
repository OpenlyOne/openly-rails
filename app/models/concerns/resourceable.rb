# frozen_string_literal: true

# Add support for resourceable methods, such as #folder?, linable, ...
module Resourceable
  extend ActiveSupport::Concern

  def folder?
    provider_mime_type_class.folder?(mime_type)
  end

  def symbolic_mime_type
    provider_mime_type_class.to_symbol(mime_type)
  end

  private

  def provider_mime_type_class
    Object.const_get("#{provider}::MimeType")
  end
end
