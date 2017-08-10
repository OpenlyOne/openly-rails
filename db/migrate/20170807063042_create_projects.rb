# frozen_string_literal: true

# Create project model
class CreateProjects < ActiveRecord::Migration[5.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.references :owner, polymorphic: true

      t.timestamps
    end
  end
end
