# frozen_string_literal: true

module VersionControl
  # A collection of files for a version controlled revision, whether committed
  # or staged
  class FileCollection
    attr_reader :revision
    delegate :repository, to: :revision

    def initialize(revision)
      @revision = revision
    end

    # Return the file's parent ID from the relative path
    def self.parent_id_from_relative_path(relative_path)
      # The parent id is the parent's basename to string
      parent_id = Pathname.new(relative_path).parent.basename.to_s

      # Return nil if parent is the working directory
      parent_id == '.' ? nil : parent_id
    end
  end
end
