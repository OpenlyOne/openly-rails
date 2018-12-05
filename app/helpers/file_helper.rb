# frozen_string_literal: true

# Define helpers needed for Google Drive Files
module FileHelper
  # Wrap block into a link_to the file.
  # If the file is a directory, wraps into an internal link to that directory.
  # If the file is not a directory, wraps into an remote link to Drive.
  def link_to_file(diff, project, options = {}, &block)
    # internal link to that folder
    if diff.folder?
      path = profile_project_folder_path(
        project.owner, project, VCS::File.id_to_hashid(diff.file_id)
      )

    # remote link to the original file on Google Drive
    else
      path = diff.link_to_remote
      options = options.reverse_merge target: '_blank'
    end

    link_to(path, options) { capture(&block) }
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

  def file_backup_path(diff, revision, project)
    if diff.folder? && revision.published?
      profile_project_revision_folder_path(
        project.owner, project, revision.id,
        VCS::File.id_to_hashid(diff.file_id)
      )
    else
      diff.backup&.link_to_remote
    end
  end
end
