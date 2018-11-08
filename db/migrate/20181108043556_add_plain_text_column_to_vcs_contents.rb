class AddPlainTextColumnToVcsContents < ActiveRecord::Migration[5.2]
  def change
    add_column :vcs_contents, :plain_text, :text, null: true
  end
end
