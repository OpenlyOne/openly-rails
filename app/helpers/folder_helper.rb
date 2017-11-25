# frozen_string_literal: true

# Define helpers needed in folder files
module FolderHelper
  # Return the color class for the change that has been made to the file
  def change_color(file)
    return 'red darken-2'     if file.deleted_since_last_commit?
    return 'green darken-2'   if file.added_since_last_commit?
    return 'amber darken-4'   if file.modified_since_last_commit?
    return 'purple darken-2'  if file.moved_since_last_commit?
    ''
  end

  # Return the color class for the change that has been made to the file
  def change_text_color(file)
    scheme = change_color(file).split(' ')
    return '' if scheme.none?

    "#{scheme.first}-text text-#{scheme.last}"
  end

  # Recursively get the folder's parents
  def collect_parents(folder)
    # stop recursion if we have arrived at the 'top'
    return [folder] unless folder.parent

    # collect parents and then append self
    collect_parents(folder.parent) << folder
  end

  # Return the HTML class for the change that has been made to the file
  def file_change_html_class(file)
    return 'changed deleted'  if file.deleted_since_last_commit?
    return 'changed added'    if file.added_since_last_commit?
    return 'changed modified' if file.modified_since_last_commit?
    return 'changed moved'    if file.moved_since_last_commit?

    'unchanged'
  end

  # Get the SVG path for the file change
  # rubocop:disable Metrics/MethodLength
  def file_change_icon(file)
    if file.deleted_since_last_commit?
      'M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,2 0 0,'\
      '0 18,19V7H6V19Z'
    elsif file.added_since_last_commit?
      'M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z'
    elsif file.modified_since_last_commit?
      'M20.71,7.04C21.1,6.65 21.1,6 20.71,5.63L18.37,3.29C18,2.9 17.35,'\
      '2.9 16.96,3.29L15.12,5.12L18.87,8.87M3,17.25V21H6.75L17.81,9.93L14.06,'\
      '6.18L3,17.25Z'
    elsif file.moved_since_last_commit?
      'M14,18V15H10V11H14V8L19,13M20,6H12L10,4H4C2.89,4 2,4.89 2,6V18A2,'\
      '2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6Z'
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Get a tooltip for the change made to the file
  def file_change_tooltip(file)
    change = file_change_html_class(file)
    return nil if change == 'unchanged'
    change.gsub('changed', 'File has been')
  end
end
