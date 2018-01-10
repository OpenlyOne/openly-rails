# frozen_string_literal: true

module VersionControl
  # A collection of revisions for a version controlled repository
  class RevisionCollection
    attr_reader :repository
    delegate :lock, :rugged_repository, to: :repository

    def initialize(repository)
      @repository = repository
    end

    # Return an array of VersionControl:Revisions that include all revisions in
    # this repository
    def all
      return @all if @all

      rugged_commits = Rugged::Walker.walk(rugged_repository,
                                           show: _last_rugged_commit,
                                           simplify: true)

      @all =
        rugged_commits.map do |commit|
          VersionControl::Revisions::Committed.new(self, commit)
        end
    end

    # Return the last (most recent) revision in this repository
    def last
      return @last if @last
      return nil unless _last_rugged_commit
      @last ||= Revisions::Committed.new(self, _last_rugged_commit)
    end

    # Resets cached instance variables and returns self for chaining
    def reload
      @last = nil
      self
    end

    private

    def _last_rugged_commit
      rugged_repository.branches['master']&.target
    end
  end
end
