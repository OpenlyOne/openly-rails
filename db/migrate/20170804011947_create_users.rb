# frozen_string_literal: true

# Create user model
class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.belongs_to :account, index: { unique: true }, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
