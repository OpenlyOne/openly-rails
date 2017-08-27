# frozen_string_literal: true

module VersionControl
  # A collection of version controlled files
  class FileCollection
    include Enumerable

    attr_reader :repository

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

    # Create a new file and return it
    def create(params)
      # Create new file
      file = VersionControl::File.create params.merge(collection: self)

      # Reload files in collection
      reload!

      # Return reference to new file
      file
    end

    # Check for the existence of a file by name (case insensitive)
    def exists?(name)
      any? { |f| f.name.casecmp(name).zero? }
    end

    # Search collection for file with name (case insensitive)
    # Raise ActiveRecord error if not findable.
    def find(name)
      file = find_by { |f| f.name.casecmp(name).zero? }
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
