# frozen_string_literal: true

# Create table for project revisions
class CreateRevisions < ActiveRecord::Migration[5.1]
  def change
    create_table :revisions do |t|
      t.belongs_to :project, null: false, foreign_key: true
      t.belongs_to :parent, null: true, foreign_key: { to_table: :revisions }
      t.belongs_to :author, null: false, foreign_key: { to_table: :profiles }
      t.boolean :is_published, null: false, default: false
      t.string :title
      t.text :summary

      # Can only have one published revision per parent
      t.index :parent_id,
              name: 'index_revisions_on_published_parent_id',
              unique: true,
              where: 'is_published IS TRUE'

      # Can only have one root revision (revision without a parent)
      t.index :project_id,
              name: 'index_revisions_on_published_root_revision',
              unique: true,
              where: 'parent_id IS NULL AND is_published IS TRUE'

      t.timestamps
    end
  end
end
