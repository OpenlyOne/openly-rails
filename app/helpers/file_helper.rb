# frozen_string_literal: true

# Define helpers needed for Google Drive Files
module FileHelper
  # Wrap block into a link_to the file.
  # If the file is a directory, wraps into an internal link to that directory.
  # If the file is not a directory, wraps into an external link to Drive.
  def link_to_file(file, project, options = {}, &block)
    # internal link to that folder
    if file.folder?
      path =
        profile_project_folder_path(project.owner, project, file.external_id)

    # external link to the original file on Google Drive
    else
      path = file.external_link
      options = options.reverse_merge target: '_blank'
    end

    link_to(path, options) { capture(&block) }
  end

  # Wrap block into a link to the file's snapshot backup
  # If the file snapshot has not been backed up, does not wrap block into a
  # link.
  def link_to_file_backup(file_snapshot, options = {}, &block)
    path = file_snapshot.backup&.file_resource&.external_link

    if path
      options = options.reverse_merge target: '_blank'
      link_to(path, options) { capture(&block) }
    else
      content_tag(:span) { capture(&block) }
    end
  end
end
