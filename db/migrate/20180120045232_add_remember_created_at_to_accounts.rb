# frozen_string_literal: true

# Add remember_created_at column to accounts to enable support for the Devise
# rememberable module
class AddRememberCreatedAtToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :remember_created_at, :datetime
  end
end
