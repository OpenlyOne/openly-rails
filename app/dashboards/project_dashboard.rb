# frozen_string_literal: true

require 'administrate/base_dashboard'

# Describe attributes of Account model
class ProjectDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    owner: Field::BelongsTo.with_options(class_name: 'Profiles::User'),
    collaborators: Field::HasMany.with_options(class_name: 'Profiles::User'),
    id: Field::Number,
    title: Field::String,
    slug: Field::String,
    description: Field::Text,
    tag_list: Field::String.with_options(searchable: false),
    is_public: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    title
    owner
    collaborators
    is_public
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    owner
    collaborators
    slug
    description
    tag_list
    is_public
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    title
    owner
    collaborators
    slug
    description
    tag_list
    is_public
  ].freeze

  # Overwrite this method to customize how accounts are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(account)
  #   "Account ##{account.id}"
  # end
end
