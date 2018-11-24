# We are no longer using resources, they can be removed.
class DropResources < ActiveRecord::Migration[5.2]
  def up
    drop_table :resources
  end

  def down
    create_table 'resources', force: :cascade do |t|
      t.string 'title', null: false
      t.text 'description'
      t.text 'mime_type', null: false
      t.bigint 'owner_id', null: false
      t.text 'link', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['owner_id'], name: 'index_resources_on_owner_id'
    end

    add_foreign_key 'resources', 'profiles', column: 'owner_id'
  end
end
