# frozen_string_literal: true

# Define helpers needed for Google Drive Files
module FileHelper
  # Disable cyclomatic complexity because all of these methods may be rather
  # long
  # rubocop:disable Metrics/CyclomaticComplexity

  # Return the external link for the given file
  def external_link_for_file(file)
    return nil unless file.mime_type.present? && file.id.present?

    case type_of_file(file)
    when :document      then "https://docs.google.com/document/d/#{file.id}"
    when :drawing       then "https://docs.google.com/drawings/d/#{file.id}"
    when :folder        then "https://drive.google.com/drive/folders/#{file.id}"
    when :form          then "https://docs.google.com/forms/d/#{file.id}"
    when :presentation  then "https://docs.google.com/presentation/d/#{file.id}"
    when :spreadsheet   then "https://docs.google.com/spreadsheets/d/#{file.id}"
    else                     "https://drive.google.com/file/d/#{file.id}"
    end
  end

  # Return the icon for the given file
  def icon_for_file(file)
    return nil unless file.mime_type.present?

    case type_of_file(file)
    when :folder
      'files/folder.png'
    else
      'https://drive-thirdparty.googleusercontent.com/' \
      "128/type/#{file.mime_type}"
    end
  end

  # Wrap block into a link_to the file.
  # If the file is a directory, wraps into an internal link to that directory.
  # If the file is not a directory, wraps into an external link to Drive.
  def link_to_file(file, project, options = {}, &block)
    # internal link to that folder
    if file.directory?
      path = profile_project_folder_path(project.owner, project, file.id)

    # external link to the original file on Google Drive
    else
      path = external_link_for_file(file)
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
      (file.directory? ? 0 : 1),
      # then sort by name in ascending order (case insensitive)
      file.name.downcase
    ]
  end

  # Convert the file's mime_type to a symbol representing its type
  def type_of_file(file)
    return nil unless file.mime_type.present?

    case file.mime_type
    when 'application/vnd.google-apps.document'     then :document
    when 'application/vnd.google-apps.drawing'      then :drawing
    when 'application/vnd.google-apps.folder'       then :folder
    when 'application/vnd.google-apps.form'         then :form
    when 'application/vnd.google-apps.presentation' then :presentation
    when 'application/vnd.google-apps.spreadsheet'  then :spreadsheet
    else                                                 :other
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity
end
