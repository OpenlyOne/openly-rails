# frozen_string_literal: true

# Define helpers needed for Google Drive Files
module FileHelper
  # Disable cyclomatic complexity because all of these methods may be rather
  # long
  # rubocop:disable Metrics/CyclomaticComplexity

  # Return the external link for the given file
  def external_link_for_file(file)
    return nil unless file.mime_type.present? && file.id.present?

    case file_type(file)
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

    case file_type(file)
    when :folder
      'files/folder.png'
    else
      'https://drive-thirdparty.googleusercontent.com/' \
      "128/type/#{file.mime_type}"
    end
  end

  # Sort files by 1) directory first and 2) file name in ascending order
  def sort_files!(files)
    files.sort_by! do |file|
      [
        (file.directory? ? 0 : 1),  # put directories first
        file.name                   # then sort by name in ascending order
      ]
    end
  end

  private

  # Convert the file's mime_type to a symbol representing its type
  def file_type(file)
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
end
