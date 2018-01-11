# frozen_string_literal: true

module VersionControl
  # A revision for a version controlled repository, whether committed or
  # staged
  class Revision
    attr_reader :repository
    delegate :lock, to: :repository

    def initialize(repository)
      @repository = repository
    end

    # Create a RevisionDiff with self as the base and the passed revision as the
    # differentiator
    def diff(differentiator)
      VersionControl::RevisionDiff.new(self, differentiator)
    end
  end
end
