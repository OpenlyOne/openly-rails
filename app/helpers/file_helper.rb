# frozen_string_literal: true

# Define helpers needed in file files
module FileHelper
  # rubocop:disable Metrics/MethodLength
  def authorized_actions_for_project_file(file, project)
    authorized_actions = []
    if can? :edit_content, file, project
      authorized_actions.push(
        name: :edit,
        link: edit_profile_project_file_path(project.owner, project, file)
      )
    end
    if can? :edit_name, file, project
      authorized_actions.push(
        name: :rename,
        link: rename_profile_project_file_path(project.owner, project, file)
      )
    end
    if can? :delete, file, project
      authorized_actions.push(
        name: :delete,
        link: delete_profile_project_file_path(project.owner, project, file)
      )
    end
    authorized_actions
  end
  # rubocop:enable Metrics/MethodLength
end
