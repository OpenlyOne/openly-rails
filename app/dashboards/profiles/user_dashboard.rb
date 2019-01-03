# frozen_string_literal: true

require 'administrate/base_dashboard'

module Profiles
  # Describe attributes of Profiles::User model
  class UserDashboard < Administrate::BaseDashboard
    # ATTRIBUTE_TYPES
    # a hash that describes the type of each of the model's fields.
    #
    # Each different type represents an Administrate::Field object,
    # which determines how the attribute is displayed
    # on pages throughout the dashboard.
    ATTRIBUTE_TYPES = {
      id: Field::Number,
      name: Field::String,
      handle: Field::String,
      account: Field::BelongsTo,
      color_scheme: Field::Select.with_options(collection: Color.options),
      picture: PaperclipField,
      banner: PaperclipField,
      about: Field::Text,
      location: Field::String,
      link_to_website: Field::String,
      link_to_facebook: Field::String,
      link_to_twitter: Field::String,
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
      name
      handle
      account
    ].freeze

    # SHOW_PAGE_ATTRIBUTES
    # an array of attributes that will be displayed on the model's show page.
    SHOW_PAGE_ATTRIBUTES = %i[
      name
      handle
      account
      color_scheme
      picture
      banner
      about
      location
      link_to_website
      link_to_facebook
      link_to_twitter
    ].freeze

    # FORM_ATTRIBUTES
    # an array of attributes that will be displayed
    # on the model's form (`new` and `edit`) pages.
    FORM_ATTRIBUTES = %i[
      name
      handle
      color_scheme
      picture
      banner
      about
      location
      link_to_website
      link_to_facebook
      link_to_twitter
    ].freeze

    # Overwrite this method to customize how users are displayed
    # across all pages of the admin dashboard.
    #
    def display_resource(user)
      "#{user.name} (@#{user.handle})"
    end
  end
end
