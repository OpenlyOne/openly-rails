# frozen_string_literal: true

# Create FileResources for representing files from cloud providers
class CreateFileResources < ActiveRecord::Migration[5.1]
  def change
    create_table :file_resources do |t|
      t.integer :provider_id, null: false
      t.text :external_id, null: false
      t.belongs_to :parent, null: true,
                            foreign_key: { to_table: :file_resources }
      t.text :name, null: true
      t.text :content_version, null: true
      t.string :mime_type, null: true
      t.boolean :is_deleted, null: false, default: false
      t.index %i[provider_id external_id], unique: true

      t.timestamps
    end
  end
end
