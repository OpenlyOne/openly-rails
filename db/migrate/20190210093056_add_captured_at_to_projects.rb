class AddCapturedAtToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :captured_at, :timestamp,
               default: -> { 'CURRENT_TIMESTAMP' },
               null: false

    Project.reset_column_information
    Project.find_each do |project|
      project.update_attribute(
        :captured_at,
        project.revisions.last&.updated_at || project.created_at
      )
    end
  end
end
