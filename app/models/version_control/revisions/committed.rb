# frozen_string_literal: true

module VersionControl
  module Revisions
    # A committed revision for a version controlled repository
    class Committed < Revision
      attr_reader :revision_collection, :id

      delegate :repository, to: :revision_collection
      delegate :tree, to: :@commit

      def initialize(revision_collection, commit)
        @revision_collection  = revision_collection
        @commit               = commit
        @id                   = commit.oid
      end

      def files
        @files ||= FileCollections::Committed.new(self)
      end
    end
  end
end
