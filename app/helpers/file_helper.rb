# frozen_string_literal: true

# Define helpers needed for Google Drive Files
module FileHelper
  # Wrap block into a link_to the file.
  # If no link to the file, wrap block into a span tag.
  def link_to_file(file, folder_path, path_parameters, options = {}, &block)
    path = file_path(file, folder_path, path_parameters)

    if path.present?
      options = options.reverse_merge target: '_blank' unless file.diff.folder?
      link_to(path, options) { capture(&block) }
    else
      content_tag(:span) { capture(&block) }
    end
  end

  # Wrap block into a link to the file's version backup
  # If the file version has not been backed up, does not wrap block into a
  # link.
  def link_to_file_backup(file, revision, project, options = {}, &block)
    path = file_backup_path(file, revision, project)

    if path.present?
      options = options.reverse_merge target: '_blank' unless file.folder?
      link_to(path, options) { capture(&block) }
    else
      content_tag(:span) { capture(&block) }
    end
  end

  def link_to_file_backup?(file, revision, project)
    file_backup_path(file, revision, project).present?
  end

  private

  # If the file is not a directory, return the external link to Drive.
  # If the file is a directory, return the internal link to that directory.
  def file_path(file, folder_path, path_parameters)
    return file.link_to_remote unless file.diff.folder?

    send(folder_path, *path_parameters, file.diff.hashed_file_id)
  end

  def file_backup_path(diff, revision, project)
    if diff.folder? && revision.published?
      profile_project_revision_folder_path(
        project.owner, project, revision.id, diff.hashed_file_id
      )
    else
      diff.backup&.link_to_remote
    end
  end
end
