# frozen_string_literal: true

class Revision
  # Generate the ancestor tree for a set of files at a given revision
  class FileAncestryTree
    # Initialize and generate tree
    def self.generate(revision:, file_ids:, depth:)
      tree = new(revision: revision, file_ids: file_ids)
      tree.recursively_load_parents(depth: depth)
      tree
    end

    def initialize(revision:, file_ids:)
      self.revision = revision
      initialize_tree(file_ids)
    end

    # Return the ancestor names for a given file ID
    def ancestors_names_for(file_id, depth:)
      ancestor_names = []
      file = find(file_id)

      (1..depth).each do
        file = find(file[:parent])
        break unless file.present?

        ancestor_names << file[:name]
      end

      ancestor_names
    end

    # Load parent records for all nil entries
    def load_parents
      return unless nil_entries.any?

      parents = fetch_records_for(nil_entries.keys)

      # add parents fetched from database
      add_entries(parents)

      # set nil entries to false (these records were not found)
      update_entries(nil_entries.keys, false)

      # add parents' parent IDs as nil entries (these records will be fetched
      # next time)
      add_nil_entries(parents.map { |parent| parent[:parent] }.compact)
    end

    # Recursively call #load_parents depth number of times
    def recursively_load_parents(depth:)
      depth.times do
        load_parents
      end
    end

    private

    attr_accessor :revision, :tree

    # Add entries, must be an array of hashes in format:
    # {id: _, name: _, parent: _}
    def add_entries(entries)
      new_entries =
        entries
        .map { |hash| [hash[:id], hash.slice(:name, :parent)] }
        .to_h
      tree.merge!(new_entries)
    end

    # Find an entry by ID or return nil
    def find(id)
      tree[id] || nil
    end

    # Set up tree with nil entrie
    def initialize_tree(file_ids)
      self.tree = {}
      add_nil_entries(file_ids)
    end

    # Return all hashes with nil value
    def nil_entries
      tree.select { |_, entry| entry.nil? }
    end

    # Add IDs with nil value
    def add_nil_entries(ids)
      nil_entry_hash = ids.map { |id| [id, nil] }.to_h
      tree.reverse_merge!(nil_entry_hash)
    end

    # Update entries of IDs with new value
    def update_entries(ids, new_value)
      updated_entries = ids.map { |id| [id, new_value] }.to_h
      tree.merge!(updated_entries)
    end

    # Fetch file snapshot records for the given IDs
    def fetch_records_for(ids)
      CommittedFile
        .connection
        .select_all(distinct_file_resources_between_revisions_with_ids(ids))
        .rows.map { |id, name, parent| { id: id, name: name, parent: parent } }
    end

    # ActiveRecord query for distinct file resources between revision and its
    # parent revision for a given array of IDs
    def distinct_file_resources_between_revisions_with_ids(ids)
      CommittedFile
        .distinct_file_resources_between_revisions(revision, revision.parent_id)
        .joins(:file_resource_snapshot)
        .select('file_resource_snapshots.name',
                'file_resource_snapshots.parent_id')
        .where(file_resource_id: ids)
    end
  end
end
