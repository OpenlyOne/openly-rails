# frozen_string_literal: true

module VersionControl
  # A single version controlled file
  class File
    attr_reader :oid, :name, :collection

    def initialize(params = {})
      @oid        = params[:oid]
      @name       = params[:name]
      @collection = params[:collection]
    end

    # Return the file's content
    def content
      @content ||= collection.lookup(oid).content
    end
  end
end
