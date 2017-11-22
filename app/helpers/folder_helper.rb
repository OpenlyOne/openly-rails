# frozen_string_literal: true

# Define helpers needed in folder files
module FolderHelper
  # Recursively get the folder's parents
  def collect_parents(folder)
    # stop recursion if we have arrived at the 'top'
    return [folder] unless folder.parent

    # collect parents and then append self
    collect_parents(folder.parent) << folder
  end
end
