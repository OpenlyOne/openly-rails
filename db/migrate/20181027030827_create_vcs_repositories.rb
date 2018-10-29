class CreateVcsRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_repositories do |t|

      t.timestamps
    end
  end
end
