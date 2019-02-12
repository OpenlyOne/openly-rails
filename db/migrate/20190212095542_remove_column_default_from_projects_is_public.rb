class RemoveColumnDefaultFromProjectsIsPublic < ActiveRecord::Migration[5.2]
  def up
    change_column_default :projects, :is_public, nil
  end

  def down
    change_column_default :projects, :is_public, false
  end
end
