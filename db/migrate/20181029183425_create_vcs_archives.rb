class CreateVcsArchives < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_archives do |t|
      t.belongs_to :repository,
                   null: false, unique: true,
                   foreign_key: { to_table: :vcs_repositories }
      t.text :external_id, null: false

      t.timestamps
    end
  end
end
