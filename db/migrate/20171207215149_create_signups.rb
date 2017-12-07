# frozen_string_literal: true

# Add Signup model to support user subscriptions
class CreateSignups < ActiveRecord::Migration[5.1]
  def change
    create_table :signups do |t|
      t.text :email

      t.timestamps
    end
  end
end
