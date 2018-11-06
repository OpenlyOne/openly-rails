# frozen_string_literal: true

class CreateVcsFileRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_file_records do |t|
      t.belongs_to :repository, null: false,
                                foreign_key: { to_table: :vcs_repositories }

      t.timestamps
    end
  end
end
