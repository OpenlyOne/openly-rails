# frozen_string_literal: true

# Define helpers needed in file files
module FileHelper
  # rubocop:disable Metrics/MethodLength
  def authorized_actions_for_project_file(file, project)
    authorized_actions = []
    if can? :edit_content, file, project
      authorized_actions.push(
        name: :edit,
        link: edit_profile_project_file_path(project.owner, project, file),
        icon: 'M20.71,7.04C21.1,6.65 21.1,6 20.71,5.63L18.37,3.29C18,2.9 ' \
              '17.35,2.9 16.96,3.29L15.12,5.12L18.87,8.87M3,'\
              '17.25V21H6.75L17.81,9.93L14.06,6.18L3,17.25Z'
      )
    end
    if can? :edit_name, file, project
      authorized_actions.push(
        name: :rename,
        link: rename_profile_project_file_path(project.owner, project, file),
        icon: 'M2.5 4v3h5v12h3V7h5V4h-13zm19 5h-9v3h3v7h3v-7h3V9z'
      )
    end
    if can? :delete, file, project
      authorized_actions.push(
        name: :delete,
        link: delete_profile_project_file_path(project.owner, project, file),
        icon: 'M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,' \
              '2 0 0,0 18,19V7H6V19Z'
      )
    end
    authorized_actions
  end
  # rubocop:enable Metrics/MethodLength
end
