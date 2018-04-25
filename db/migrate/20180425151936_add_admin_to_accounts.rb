# frozen_string_literal: true

# Add admin column to accounts to indicate whether account has admin privileges
class AddAdminToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :admin, :boolean, default: false
  end
end
