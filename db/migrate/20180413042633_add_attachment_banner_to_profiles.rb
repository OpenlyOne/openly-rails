# frozen_string_literal: true

# Add banner column to profiles table
class AddAttachmentBannerToProfiles < ActiveRecord::Migration[5.1]
  def self.up
    change_table :profiles do |t|
      t.attachment :banner
    end
  end

  def self.down
    remove_attachment :profiles, :banner
  end
end
