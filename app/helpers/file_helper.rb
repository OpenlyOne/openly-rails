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

  # Sort files according to sort order
  def sort_files!(files)
    files.sort_by! do |file|
      sort_order_for_files(file)
    end
  end

  # Return the sort order for files.
  #
  # Files are sorted by:
  # 1) directory first and
  # 2) file name in ascending alphabetical order case insensitive
  #
  # Example use:
  # files.sort_by! { |file| sort_order_for_files(file) }
  # file_diffs.sort_by! { |diff| sort_order_for_files(diff.file_is_or_was) }
  def sort_order_for_files(file)
    [
      # put directories first
      (file.folder? ? 0 : 1),
      # then sort by name in ascending order (case insensitive)
      file.name.downcase
    ]
  end
end
