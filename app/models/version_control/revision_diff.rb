# frozen_string_literal: true

module VersionControl
  # The diff (or change) between two revisions in the repository
  class RevisionDiff
    attr_reader :base, :differentiator

    # Initialize an instance of RevisionDiff given two revisions.
    # The base should be the more current revision, the differentiator the less
    # current one.
    def initialize(base, differentiator)
      @base           = base
      @differentiator = differentiator
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
  end
end
