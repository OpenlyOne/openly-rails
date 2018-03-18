# frozen_string_literal: true

# Add support for resourceable methods, such as #folder?, linable, ...
module Resourceable
  extend ActiveSupport::Concern

  included do
    belongs_to :thumbnail, class_name: 'FileResource::Thumbnail', optional: true
  end

  def folder?
    provider_mime_type_class.folder?(mime_type)
  end

  def external_link
    provider_link_class.for(external_id: external_id, mime_type: mime_type)
  end

  def icon
    provider_icon_class.for(mime_type: mime_type)
  end

  def symbolic_mime_type
    provider_mime_type_class.to_symbol(mime_type)
  end

  private

  def provider_icon_class
    Object.const_get("#{provider}::Icon")
  end

  def provider_link_class
    Object.const_get("#{provider}::Link")
  end

  def provider_mime_type_class
    Object.const_get("#{provider}::MimeType")
  end
end
