class AddIsPremiumToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :is_premium, :boolean, default: false, null: false
  end
end
