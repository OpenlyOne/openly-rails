# frozen_string_literal: true

# Add profile_picture attachment to profiles
class AddAttachmentPictureToProfiles < ActiveRecord::Migration[5.1]
  def up
    change_table :profiles do |t|
      t.attachment :picture
    end
  end

  def down
    remove_attachment :profiles, :picture
  end
end
