# frozen_string_literal: true

# Create the accounts for devise
class DeviseCreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

      t.timestamps null: false
    end

    add_index :accounts, :email, unique: true
  end
end
