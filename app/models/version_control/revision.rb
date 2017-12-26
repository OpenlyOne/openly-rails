# frozen_string_literal: true

module VersionControl
  # A revision for a version controlled repository, whether committed or
  # staged
  class Revision
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end
  end
end
