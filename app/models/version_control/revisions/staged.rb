# frozen_string_literal: true

module VersionControl
  module Revisions
    # A staged revision for a version controlled repository
    class Staged < Revision
      delegate :rugged_repository, to: :repository
      delegate :index, to: :rugged_repository, prefix: :repository

      def files
        @files ||= FileCollections::Staged.new(self)
      end

      # Save all staged files by writing them to a tree object
      def save
        lock do
          # clear the index and add all files from working directory
          repository_index.clear
          repository_index.add_all

          # add last revision info
          add_last_revision_information_to_index

          # write the tree object
          repository_index.write_tree
        end
      end

      private

      # Write the object ID of the last revision in this repository to a file
      # named .last-revision in the top-level tree. The information in this file
      # is used to verify that the tree is valid (if actual last revision
      # matches the ID in the .last-revision file).
      def add_last_revision_information_to_index
        last_revision_oid = repository.revisions.last&.id
        blob_oid = rugged_repository.write(last_revision_oid.to_s, :blob)
        repository_index.add(
          path: '.last-revision',
          oid: blob_oid,
          mode: 0o0100644
        )
      end
    end
  end
end
