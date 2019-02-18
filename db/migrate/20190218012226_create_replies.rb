class CreateReplies < ActiveRecord::Migration[5.2]
  def change
    create_table :replies do |t|
      t.belongs_to :author, foreign_key: { to_table: :profiles }, null: false
      t.belongs_to :contribution, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end
  end
end
