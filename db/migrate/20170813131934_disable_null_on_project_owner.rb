# frozen_string_literal: true

# Do not allow null values for project owner
class DisableNullOnProjectOwner < ActiveRecord::Migration[5.1]
  def change
    change_column_null :projects, :owner_type, false
    change_column_null :projects, :owner_id, false
  end
end
