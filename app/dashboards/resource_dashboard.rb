# frozen_string_literal: true

require 'administrate/base_dashboard'

# Describe attributes of Resource model
class ResourceDashboard < Administrate::BaseDashboard
  # Define options for the mime_type select field
  def self.mime_types
    Providers::GoogleDrive::MimeType::MIME_TYPES.values.sort
  end

  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    owner: Field::BelongsTo.with_options(class_name: 'Profiles::User'),
    id: Field::Number,
    title: Field::String,
    description: Field::Text,
    mime_type: Field::Select.with_options(collection: mime_types),
    link: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    owner
    id
    title
    description
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    owner
    id
    title
    description
    mime_type
    link
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    owner
    title
    description
    mime_type
    link
  ].freeze

  # Overwrite this method to customize how resources are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(resource)
  #   "Resource ##{resource.id}"
  # end
end
