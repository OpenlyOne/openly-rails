# frozen_string_literal: true

module VersionControl
  module FileCollections
    # A collection of committed files for a version controlled repository
    class Committed < FileCollection
      delegate :lookup, to: :repository

      def initialize(revision)
        @revision = revision
      end

      # Return true if file with given ID exists among files of revision
      # If an array is passed, will find and return a hash in the form of:
      # {'12345' => true, 'abcdef' => false, id => does_id_exist?}
      # Return false if file does not exist.
      def exists?(id_or_ids)
        entries = find_entries_by_ids(Array.wrap(id_or_ids).compact).compact

        # If we are only looking for a single ID, return true or false now
        return entries.any? unless id_or_ids.is_a? Array

        # Transform paths into a hash in the form of 'id' => true/false
        id_or_ids.compact.map do |id|
          [id, entries.any? { |entry| entry[:name] == id }]
        end.to_h
      end

      # Find a single committed file from a tree entry
      # Return nil if not found
      def find_by_entry(entry)
        VersionControl::Files::Committed.new(self, metadata_for(entry))

      # Return nil if file was not found
      rescue Errno::ENOENT, Errno::EINVAL, Rugged::InvalidError
        nil
      end

      # Find a file by its id
      # If an array is passed, will find and return all matching files
      # Return nil if not found
      def find_by_id(id_or_ids)
        entries = find_entries_by_ids Array.wrap(id_or_ids)
        files = entries.map do |entry|
          find_by_entry(entry)
        end

        # Return array if array was passed. Single instance, otherwise.
        id_or_ids.is_a?(Array) ? files : files.first
      end

      # Find a file by its path
      # If an array is passed, will find and return all matching files
      # Return nil if not found
      def find_by_path(path_or_paths)
        entries = find_entries_by_paths Array.wrap(path_or_paths)
        files = entries.map do |entry|
          find_by_entry(entry)
        end

        # Return array if array was passed. Single instance, otherwise.
        path_or_paths.is_a?(Array) ? files : files.first
      end

      private

      # Find entries for an array of ids by recursively searching through
      # the revision tree.
      def find_entries_by_ids(ids)
        entries = []
        revision.tree.walk(:preorder) do |root, entry|
          # skip if this is not an entry we are looking for
          next unless ids.include? entry[:name]

          # found a match! Add path parameter and store
          entries << entry.merge(path: "#{root}#{entry[:name]}")
        end

        # sort by ids
        ids.map do |id|
          entries.detect { |entry| entry[:name] == id }
        end
      end

      # Find entries for an array of paths by recursively searching through
      # the revision tree. For details about the recursion,
      # read #find_entries_in_tree_by_paths(current_path, all_paths, tree).
      def find_entries_by_paths(paths)
        # recursively find entries
        entries = find_entries_in_tree_by_paths(nil, paths, revision.tree)

        # flatten entries
        entries.flatten!

        # sort by paths
        paths.map do |path|
          entries.detect { |entry| entry[:path] == path }
        end
      end

      # Recursively find the entries for the provided all_paths within the given
      # tree. This method is meant to minimize the number of trees we need to
      # touch. Each tree is touched at most once.
      # To do this, the recursive method first uses paths_to_paths_map to group
      # paths by first segment, e.g. 'root' for 'root/folder/file'.
      # For each path group, we collect entries and trigger this method again.
      # rubocop:disable Metrics/MethodLength
      def find_entries_in_tree_by_paths(current_path, all_paths, tree)
        results = []

        # Group paths by initial path segment
        group_paths_by_segment(all_paths.compact).each do |segment, paths|
          # In current tree: Find the entry with the given segment
          entry = tree.get_entry(segment)

          next unless entry

          # Add path information to entry
          entry[:path] = [current_path, segment].compact.join('/')

          # If paths include self (nil), add entry to results
          results << entry if paths.include? nil

          # Go to next path group if no non-nil paths are left in this group
          next unless paths.any?

          # Paths are remaining, let us recursively fetch them
          subtree = lookup(entry[:oid])
          results << find_entries_in_tree_by_paths(entry[:path], paths, subtree)
        end

        # Return results
        results
      end
      # rubocop:enable Metrics/MethodLength

      # Groups a set of paths by their first segment into a hash.
      # Example:
      # ['root', 'root/folder', 'base', 'base/file']
      # becomes
      # {'root': [nil, 'folder'], 'base': [nil, 'file']}
      def group_paths_by_segment(paths)
        paths
          .map { |p| p.split('/', 2) }
          .group_by(&:first)
          .map { |k, v| [k, v.map(&:second)] }
          .to_h
      end

      # Load the YAML metadata from the provided entry
      def load_metadata(entry)
        metadata_text = lookup(metadata_entry_from_file_entry(entry)[:oid]).text

        YAML.safe_load(
          metadata_text,
          Settings.whitelisted_yaml_classes
        )&.symbolize_keys
      end

      # Get the metadata entry based on the file entry
      def metadata_entry_from_file_entry(entry)
        # If we are already having a blob, we are good
        return entry if entry[:type] == :blob

        # If we are having a tree, open up the tree and find the '.self' entry
        # that houses the metadata
        lookup(entry[:oid])['.self']
      end

      # Return the metadata for a file in this repository identified by its
      # tree entry
      def metadata_for(entry)
        # Raise error if entry is not a Hash
        raise(Errno::EINVAL, 'Entry must be a Hash.') unless entry.is_a? Hash

        load_metadata(entry).merge(
          id: entry[:name],
          parent_id: self.class.parent_id_from_relative_path(entry[:path]),
          path: entry[:path],
          git_oid: entry[:oid]
        )
      end
    end
  end
end
