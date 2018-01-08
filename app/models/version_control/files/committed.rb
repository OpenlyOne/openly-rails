# frozen_string_literal: true

module VersionControl
  module Files
    # A committed file in a version controlled repository
    class Committed < VersionControl::File
      # Return an array of this file's ancestors (parent, parent of parent)
      # all the way up to the root folder.
      # The first array element is the immediate parent, the last array element
      # is the root folder.
      # Return nil if parent_id does not exist
      def ancestors
        return @ancestors if @ancestors
        return nil if path.nil?

        # Ancestor path as string
        ancestor_path = Pathname.new(path).parent.cleanpath
        ancestor_paths = []

        # loop through ancestors until we reach the end
        until ancestor_path == Pathname.new('').cleanpath
          ancestor_paths << ancestor_path.to_s
          ancestor_path = ancestor_path.parent
        end

        # Return ancestors
        @ancestors = file_collection.find_by_path(ancestor_paths)
      end

      # The files contained within this file, if any
      def children
        # If children are already set, return
        return @children if @children

        # If file is not a directory, return nil
        return nil unless directory?

        child_entries = file_collection.lookup(@git_oid).entries

        # Ignore any entries starting with periods
        child_entries.reject! { |entry| entry[:name].first == '.' }

        # Initialize and return children
        @children ||=
          child_entries.map do |entry|
            entry[:path] = "#{path}/#{entry[:name]}"
            file_collection.find_by_entry(entry)
          end
      end
    end
  end
end
