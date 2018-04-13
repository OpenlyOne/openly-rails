# frozen_string_literal: true

# Add link to website, Facebook, and Twitter to profiles
class AddWebLinksToProfiles < ActiveRecord::Migration[5.1]
  def change
    add_column :profiles, :link_to_website, :text
    add_column :profiles, :link_to_facebook, :text
    add_column :profiles, :link_to_twitter, :text
  end
end
