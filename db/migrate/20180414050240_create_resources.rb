# frozen_string_literal: true

# Add resources that belong to profiles
class CreateResources < ActiveRecord::Migration[5.1]
  def change
    create_table :resources do |t|
      t.string :title, null: false
      t.text :description
      t.text :mime_type, null: false
      t.belongs_to :owner, foreign_key: { to_table: :profiles }, null: false
      t.text :link, null: false

      t.timestamps
    end
  end
end
