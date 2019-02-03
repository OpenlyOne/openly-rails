class CreateContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :contributions do |t|
      t.belongs_to :project, foreign_key: true, null: false
      t.belongs_to :creator, foreign_key: { to_table: :profiles }, null: false
      t.string :title, null: false
      t.text :description, null: false

      t.timestamps
    end
  end
end
