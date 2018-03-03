# frozen_string_literal: true

# Define helpers needed for working with file diffs
module FileDiffHelper
  include FileHelper

  # Return the color class for the change that has been made to the file
  def color_for_file_diff_change(file_diff_change)
    case file_diff_change
    when :added     then 'green darken-2'
    when :modified  then 'amber darken-4'
    when :moved     then 'purple darken-2'
    when :renamed   then 'blue darken-2'
    when :deleted   then 'red darken-2'
    end
  end

  # Return the HTML class for the change that has been made to the file
  def html_class_for_file_diff_changes(file_diff_changes)
    return 'unchanged' if file_diff_changes.empty?

    "changed #{file_diff_changes.join(' ')}"
  end

  # Get the SVG path for the file change
  # rubocop:disable Metrics/MethodLength
  def icon_for_file_diff_change(file_diff_change)
    case file_diff_change
    when :added
      'M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z'
    when :modified
      'M20.71,7.04C21.1,6.65 21.1,6 20.71,5.63L18.37,3.29C18,2.9 17.35,'\
      '2.9 16.96,3.29L15.12,5.12L18.87,8.87M3,17.25V21H6.75L17.81,9.93L14.06,'\
      '6.18L3,17.25Z'
    when :moved
      'M14,18V15H10V11H14V8L19,13M20,6H12L10,4H4C2.89,4 2,4.89 2,6V18A2,'\
      '2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6Z'
    when :renamed
      'M3,12H6V19H9V12H12V9H3M9,4V7H14V19H17V7H22V4H9Z'
    when :deleted
      'M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,2 0 0,'\
      '0 18,19V7H6V19Z'
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Sort files according to sort order (see FileHelper#sort_order_for_files)
  def sort_file_diffs!(file_diffs)
    file_diffs.sort_by! do |file_diff|
      sort_order_for_files(file_diff.current_or_previous_snapshot)
    end
  end

  # Return the text color class for the change that has been made to the file
  def text_color_for_file_diff_change(file_diff_change)
    scheme = color_for_file_diff_change(file_diff_change)&.split(' ')
    return nil if scheme.nil?

    "#{scheme.first}-text text-#{scheme.last}"
  end

  # Get a tooltip for the change made to the file
  def tooltip_for_file_diff_change(file_diff_change)
    case file_diff_change
    when :added     then 'File has been added'
    when :modified  then 'File has been modified'
    when :moved     then 'File has been moved'
    when :renamed   then 'File has been renamed'
    when :deleted   then 'File has been deleted'
    end
  end
end
