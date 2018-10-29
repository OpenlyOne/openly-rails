class CreateVcsCommits < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_commits do |t|
      t.belongs_to :branch, null: false, foreign_key: { to_table: :vcs_branches }
      t.belongs_to :parent, foreign_key: { to_table: :vcs_commits }
      t.belongs_to :author, null: false, foreign_key: { to_table: :profiles }
      t.boolean :is_published, null: false, default: false
      t.string :title
      t.text :summary

      # Can only have one published revision per parent
      t.index :parent_id,
              name: 'index_commits_on_published_parent_id',
              unique: true,
              where: 'is_published IS TRUE'

      # Can only have one root commit (commit without a parent)
      t.index :branch_id,
              name: 'index_commits_on_published_root_commit',
              unique: true,
              where: 'parent_id IS NULL AND is_published IS TRUE'

      t.timestamps
    end
  end
end
