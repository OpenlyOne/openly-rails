# frozen_string_literal: true

# Create project setups table for tracking setup status of project
class CreateProjectSetups < ActiveRecord::Migration[5.1]
  def change
    create_table :project_setups do |t|
      t.belongs_to :project, foreign_key: true, null: false,
                             index: { unique: true }
      t.boolean :is_completed, null: false, default: false

      t.timestamps
    end
  end
end
