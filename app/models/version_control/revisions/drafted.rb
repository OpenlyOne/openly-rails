# frozen_string_literal: true

module VersionControl
  module Revisions
    # A drafted revision for a version controlled repository
    class Drafted < Revision
      include ActiveModel::Validations

      attr_reader :summary, :tree_id

      # Validations
      # Summary must be present
      validates :summary, presence: true
      validate :last_revision_id_matches_actual_last_revision_id

      def initialize(repository, tree_id)
        @tree_id = tree_id
        super(repository)
      end

      # Commit the drafted revision to the repository, making the revision
      # permanent
      def commit(summary, author)
        lock do
          @summary = summary
          @author = author

          return false unless valid?

          Rugged::Commit.create(
            repository.rugged_repository,
            commit_options_hash
          )
        end
      end

      # A file collection for the files in this revision
      def files
        @files ||= FileCollections::Committed.new(self)
      end

      # Return the tree for this revision draft
      def tree
        return nil unless @tree_id.present?
        @tree ||= repository.lookup @tree_id
      end

      private

      # Generate the options for the commit object
      def commit_options_hash
        author = @author.merge(time: Time.zone.now.utc)
        {
          tree: tree,
          author: author,
          committer: author,
          message: @summary,
          parents: [last_revision_id].compact,
          update_ref: 'HEAD'
        }
      end

      # Get the object ID of the last revision stored in .last-revision file
      def last_revision_id
        return @last_revision_id if @last_revision_id.present?

        # Find the entry for .last-revision in the tree
        last_revision_entry =
          tree.entries.find { |entry| entry[:name] == '.last-revision' }

        # Retrieve contents of last commit blob
        @last_revision_id = repository.lookup(last_revision_entry[:oid]).text

        # Return last commit ID or nil
        @last_revision_id.present? ? @last_revision_id : nil
      end

      # Ensure that the last revision id (from the tree's file) matches the
      # ID of the repository's actual last revision
      # If not, add an error.
      def last_revision_id_matches_actual_last_revision_id
        return if last_revision_id == repository.revisions.last&.id
        errors[:last_revision_id] << 'must match id of actual last revision'
      end
    end
  end
end
