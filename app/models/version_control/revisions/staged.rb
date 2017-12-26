# frozen_string_literal: true

module VersionControl
  module Revisions
    # A staged revision for a version controlled repository
    class Staged < Revision
      def files
        @files ||= FileCollections::Staged.new(self)
      end
    end
  end
end
