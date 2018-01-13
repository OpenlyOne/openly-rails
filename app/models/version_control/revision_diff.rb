# frozen_string_literal: true

module VersionControl
  # The diff (or change) between two revisions in the repository
  class RevisionDiff
    attr_reader :base, :differentiator
    delegate :id, to: :base, prefix: true
    delegate :id, to: :differentiator, prefix: true

    # Initialize an instance of RevisionDiff given two revisions.
    # The base should be the more current revision, the differentiator the less
    # current one.
    # TODO: Should probably swap the order (it makes more sense to say:
    #       "generate the change from revision B to revision A" than to say
    #       "generate the change to revision A from revision B"
    #       Maybe call the arguments from_revision, to_revision
    def initialize(base, differentiator)
      @base           = base
      @differentiator = differentiator
    end

    # Return an array of FileDiffs consisting of the files that have changed
    # from differentiator to base
    def changed_files_as_diffs
      files_to_diffs(
        _files_of_blobs_added_to_base,
        _files_of_blobs_deleted_from_differentiator,
        _files_of_blobs_added_to_base.map(&:id) |
        _files_of_blobs_deleted_from_differentiator.map(&:id)
      ).select(&:changed?)
      # TODO: Eliminate unchanged diffs at the delta level before initializing
      # =>    files, so we don't need to run #select(&:changed?) at the end.
    end

    # Generate a FileDiff between base and differentiator revision for the file
    # with the provided ID.
    # Raise error if file is found in neither base nor differentiator revision.
    def diff_file(id)
      base_file           = base&.files&.find_by_id(id)
      differentiator_file = differentiator&.files&.find_by_id(id)

      # Initialize the FileDiff for base and differentiator
      if base_file.present? || differentiator_file.present?
        VersionControl::FileDiff.new(self, base_file, differentiator_file)

      # File was not found, raise error!
      else
        raise ActiveRecord::RecordNotFound,
              "Couldn't find diff for file with id: #{id}"
      end
    end

    # Generate an array of FileDiffs from the passed base files, differentiator
    # files, and filter of IDs
    def files_to_diffs(base_files, differentiator_files, filter_of_ids)
      base_files            = Array.wrap(base_files)
      differentiator_files  = Array.wrap(differentiator_files)

      # Cycle through filters and create a FileDiff for each filter ID
      Array.wrap(filter_of_ids).map do |id|
        VersionControl::FileDiff.new(
          self,
          base_files.find           { |file| file&.id == id },
          differentiator_files.find { |file| file&.id == id }
        )
      end
    end

    # Lock the repository if the base is stage
    def lock_if_base_is_stage(&_block)
      if base&.is_a? VersionControl::Revisions::Staged
        base.lock { yield }
      else
        yield
      end
    end

    def repository
      base&.repository || differentiator&.repository
    end

    private

    delegate :rugged_repository, to: :repository
    delegate :tree, to: :base, prefix: true, allow_nil: true
    delegate :tree, to: :differentiator, prefix: true, allow_nil: true

    # Return the files of the blob objects that were added to base
    def _files_of_blobs_added_to_base
      @_files_of_blobs_added_to_base ||=
        base.files.find_by_path(
          _paths_from_rugged_deltas_for(:added_blobs)
        )
    end

    # Return the files of the blob objects that were deleted from differentiator
    def _files_of_blobs_deleted_from_differentiator
      return [] if differentiator.nil?

      @_files_of_blobs_deleted_from_differentiator ||=
        differentiator.files.find_by_path(
          _paths_from_rugged_deltas_for(:deleted_blobs)
        )
    end

    # Filter an array of delta file hashes to remove files that should not be in
    # there: empty objects, root, commit metadata, ..
    # REVIEW@beta: We should get rid of root folders in our repositories
    #              (we will only commit descendants) and we should also
    #              eliminate all metadata in commits by then.
    def _filter_delta_file_hashes!(file_hashes)
      # Drop objects that are empty (only 0s)
      file_hashes.reject! { |hash| hash[:oid].match?(/^0+$/) }

      # Drop commit meta information files (dot-files with top-level path)
      file_hashes.reject! { |hash| hash[:path].start_with? '.' }

      # Drop the metadata file for the root folder, if present
      file_hashes.reject! { |hash| hash[:path].split('/')[1].start_with? '.' }
    end

    # Extract and return paths of blobs for :new_file or :old_file
    def _paths_from_rugged_deltas_for(type_of_blobs)
      # Collect the correct type of delta file hash (new_file vs old_file)
      file_hash_key = (type_of_blobs == :added_blobs ? :new_file : :old_file)
      file_hashes = _rugged_deltas.map { |delta| delta.send(file_hash_key) }

      # Filter file hashes
      _filter_delta_file_hashes!(file_hashes)

      # Keep only paths
      paths = file_hashes.map { |hash| hash[:path] }
      # Convert metadata paths to file paths
      paths.map { |path| VersionControl::File.metadata_path_to_file_path path }
    end

    # Return the array of Rugged::Diff::Deltas by diffing differentiator tree
    # to base tree
    def _rugged_deltas
      @_rugged_deltas ||=
        Rugged::Tree.diff(
          rugged_repository,
          differentiator_tree,
          base_tree
        ).deltas
    end
  end
end
