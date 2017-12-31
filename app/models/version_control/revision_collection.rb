# frozen_string_literal: true

module VersionControl
  # A collection of revisions for a version controlled repository
  class RevisionCollection
    attr_reader :repository
    delegate :lock, to: :repository

    def initialize(repository)
      @repository = repository
    end

    # Return the last (most recent) revision in this repository
    def last
      @last ||=
        lock do
          last_commit = repository.rugged_repository.branches['master']&.target
          return nil unless last_commit.present?
          Revisions::Committed.new(self, last_commit)
        end
    end
  end
end
