class CreateVcsContents < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_contents do |t|
      t.belongs_to :repository, foreign_key: { to_table: :vcs_repositories },
                                null: false

      t.timestamps
    end
  end
end
