# frozen_string_literal: true

module VersionControl
  # A collection of version controlled files
  class FileCollection
    include Enumerable

    # Delegate lookup, so that File can look up its contents
    delegate :lookup, to: :@repository

    # Alias #find to #find_by so that we can override find
    alias find_by find

    # Create a new instance
    def initialize(repository)
      @repository = repository
      unless @repository.is_a?(VersionControl::Repository)
        raise 'VersionControl::FileCollection must initialized with a ' \
              'VersionControl::Repository instance'
      end

      # initialize files
      reload!
    end

    # Each block for use as Enumerable
    def each(&block)
      @files.each(&block)
    end

    # Create a new file
    # Return true on success
    # Return false on error
    def create(name, content, message, author)
      # Write the file
      blob_oid = @repository.write content, :blob

      # Stage the file
      @repository.reset_index!
      @repository.index.add path: name, oid: blob_oid, mode: 0o100644

      # Commit to master
      return false unless @repository.commit message, author

      # Reload self
      reload!
      true
    end

    # Search collection for file with name.
    # Raise ActiveRecord error if not findable.
    def find(name)
      file = find_by { |f| f.name == name }
      raise ActiveRecord::RecordNotFound if file.nil?
      file
    end

    # Reload files from last commit on master
    def reload!
      @files = []

      # abort here if there are no commits on master
      return self if @repository.branches['master'].nil?

      # initialize files
      @repository.branches['master'].target.tree.each do |file|
        @files << VersionControl::File.new(
          collection: self,
          name:       file[:name],
          oid:        file[:oid].to_s
        )
      end

      self
    end
  end
end
