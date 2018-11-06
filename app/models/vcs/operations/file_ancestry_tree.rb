# frozen_string_literal: true

module VCS::Operations
  # Generate the ancestor tree for a set of files at a given revision
  class FileAncestryTree
    # Initialize and generate tree
    # MUST PASS file_record_ids!
    def self.generate(commit:, parent_commit: nil, file_record_ids:, depth:)
      tree = new(commit: commit,
                 parent_commit: parent_commit,
                 file_record_ids: file_record_ids)
      # Load generations depth + 1 times because 1st generation is just current
      # files
      tree.recursively_load_generations(depth: depth + 1)
      tree
    end

    def initialize(commit:, parent_commit: nil, file_record_ids:)
      self.commit = commit
      self.parent_commit = parent_commit || commit.parent
      initialize_tree(file_record_ids)
    end

    # Return the ancestor names for a given file ID
    def ancestors_names_for(file_record_id, depth:)
      ancestor_names = []
      file = find(file_record_id)

      (1..depth).each do
        file = find(file[:parent])
        break unless file.present?

        ancestor_names << file[:name]
      end

      ancestor_names
    end

    # Load records for all nil entries
    def load_generation
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

    # Recursively call #load_generation depth number of times
    def recursively_load_generations(depth:)
      depth.times do
        load_generation
      end
    end

    private

    attr_accessor :commit, :tree, :parent_commit

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
      VCS::CommittedFile
        .connection
        .select_all(distinct_file_resources_between_revisions_with_ids(ids))
        .rows.map { |id, name, parent| { id: id, name: name, parent: parent } }
    end

    # ActiveRecord query for distinct file resources between revision and its
    # parent revision for a given array of IDs
    def distinct_file_resources_between_revisions_with_ids(ids)
      VCS::CommittedFile
        .distinct_file_resources_between_commits(commit, parent_commit&.id)
        .joins(:file_snapshot)
        .select("#{snapshot_table_name}.name",
                "#{snapshot_table_name}.file_record_parent_id")
        .where("#{snapshot_table_name}": { file_record_id: ids })
    end

    def snapshot_table_name
      VCS::FileSnapshot.table_name
    end
  end
end
