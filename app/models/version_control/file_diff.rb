# frozen_string_literal: true

module VersionControl
  # The diff (or change) between two version controlled files
  class FileDiff
    attr_reader :revision_diff, :base, :differentiator

    # Initialize an instance of FileDiff given an instance of RevisionDiff, a
    # base file, and a differentiator file.
    # The base should be the more current file, the differentiator the less
    # current one.
    def initialize(revision_diff, base, differentiator)
      @revision_diff  = revision_diff
      @base           = base
      @differentiator = differentiator
    end

    # Return the ancestors of base.
    # If base is nil, go through ancestors of differentiator and attempt to
    # find differentiator's ancestors within revision_base. Once we find one
    # ancestor that exists in both revision_base and differentiator_revision,
    # we combine the (dead) ancestors of differentiator with the (living) ones
    # that exist in base.
    # This combining is necessary because when a folder is deleted from base,
    # differentiator's ancestors only give us insight into the ancestors at the
    # differentiator revision. However, some of the ancestors themselves may
    # have been moved or renamed in revision_base and we want our ancestry chain
    # to reflect that.
    def ancestors_of_file
      # Return ancestors_of_file if already determined
      @ancestors_of_file ||=

        # If base is present, return base's ancestors
        base&.ancestors ||

        # Otherwise, return a combination of differentiator and base ancestors
        revision_diff.lock_if_base_is_stage do
          # Cycle through differentiator's ancestors and collect them until we
          # encounter the first ancestor that exists in revision base.
          living_ancestor = nil
          dead_ancestors = differentiator.ancestors.take_while do |ancestor|
            living_ancestor = revision_base.files.find_by_id(ancestor.id)
            living_ancestor.nil?
          end

          # Return dead and living ancestors
          dead_ancestors.concat [living_ancestor], living_ancestor.ancestors
        end
    end

    # Has the base been added since differentiator? In other words, does base
    # exist and differentiator does not?
    def been_added?
      @been_added ||= base.present? && differentiator.nil?
    end

    # Are there any changes from differentiator to base? For example, has base
    # been added since differentiator?
    def been_changed?
      @been_changed ||=
        been_added? || been_modified? || been_moved? || been_deleted?
    end

    # Has the base been modified (content or file name) since differentiator?
    # In other words, do base and differentiator have different modified times?
    def been_modified?
      @been_modified ||= base&.modified_time.present? &&
                         differentiator&.modified_time.present? &&
                         base.modified_time > differentiator.modified_time
    end

    # Has the base been moved since differentiator? In other words, do base
    # and differentiator belong to different parents?
    def been_moved?
      @been_moved ||= base&.parent_id.present? &&
                      differentiator&.parent_id.present? &&
                      base.parent_id != differentiator.parent_id
    end

    # Has the base been deleted since differentiator? In other words, does base
    # not exist and differentiator does?
    def been_deleted?
      @been_deleted ||= base.nil? && differentiator.present?
    end

    # Return an array of diffs for the children of base and differentiator.
    #
    # The following children are included:
    # * Children that have remained in base since revision differentiator
    # * Children that have been added to base since revision differentiator
    # * Children that have been deleted from base since revision differentiator
    #
    # The following children are not included:
    # * Children that have been removed from base since differentiator but live
    #   on elsewhere within the repository
    def children_as_diffs
      @children_as_diffs ||=
        revision_diff.lock_if_base_is_stage do
          diffs_of_children_that_have_remained +
            diffs_of_children_that_have_been_added +
            diffs_of_children_that_have_been_deleted
        end
    end

    # Return base. If nil, return differentiator.
    def file_is_or_was
      base || differentiator
    end

    # ID of base or differentiator
    def id_is_or_was
      file_is_or_was&.id
    end

    # Is base a directory? If base is nil, is differentiator a directory?
    # rubocop:disable Style/PredicateName
    def is_or_was_directory?
      file_is_or_was&.directory?
    end
    # rubocop:enable Style/PredicateName

    # Mime type of base or differentiator
    def mime_type_is_or_was
      file_is_or_was&.mime_type
    end

    # Name of base or differentiator
    def name_is_or_was
      file_is_or_was&.name
    end

    private

    delegate :base, :differentiator, to: :revision_diff, prefix: :revision

    # Collect the ids of the children of base
    def base_children_ids
      base&.children&.collect(&:id) || []
    end

    # Collect the ids of the children of differentiator
    def differentiator_children_ids
      differentiator&.children&.collect(&:id) || []
    end

    # Return an array of diffs for children that have been added to base since
    # revision_differentiator
    def diffs_of_children_that_have_been_added
      return @diffs_of_added_children if @diffs_of_added_children

      # Get the ids of files that have been added to base
      added_files_ids = base_children_ids - differentiator_children_ids

      # Create a diff for every added child ID, with differentiator being either
      # the existing file in differentiator's revision or nil
      @diffs_of_added_children =
        revision_diff.files_to_diffs(
          base&.children,
          # Try to find added files in revision of differentiator
          revision_differentiator&.files&.find_by_id(added_files_ids),
          added_files_ids
        )
    end

    # Return an array of diffs for children that have remained in base from
    # revision_differentiator
    def diffs_of_children_that_have_remained
      # Create a diff for every child ID found in both base and differentiator
      @diffs_of_remained_children ||=
        revision_diff.files_to_diffs(
          base&.children,
          differentiator&.children,
          base_children_ids & differentiator_children_ids
        )
    end

    # Return an array of diffs for children that have been deleted from
    # differentiator in revision_base
    def diffs_of_children_that_have_been_deleted
      @diffs_of_deleted_children ||=
        revision_diff.lock_if_base_is_stage do
          # Get the ids of files that have been deleted or moved out from
          # differentiator
          removed_file_ids = differentiator_children_ids - base_children_ids

          # Create a diff for every deleted child ID that no longer exists
          revision_diff.files_to_diffs(
            [],
            differentiator&.children,
            # Determine which removed files still exist in base and reject all
            # the file ids that exist in base (so that we only keep ids of files
            # that do not exist in base)
            revision_base&.files&.exists?(removed_file_ids)
                                &.reject { |_, v| v }&.keys
          )
        end
    end
  end
end
