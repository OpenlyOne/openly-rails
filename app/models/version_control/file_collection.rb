# frozen_string_literal: true

module VersionControl
  # A collection of files for a version controlled revision, whether committed
  # or staged
  class FileCollection
    attr_reader :revision
    delegate :repository, to: :@revision
    delegate :lock, :workdir, to: :repository

    def initialize(revision)
      @revision = revision
    end
  end
end
