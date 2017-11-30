# frozen_string_literal: true

module VersionControl
  # Wrapper for Rugged2 repositories (which is a wrapper for libgit2
  # (#wrapception))
  class Repository
    delegate  :bare?,
              :path,
              :workdir,
              to: :@rugged_repository

    # Create a new instance with a Rugged::Repository repo
    def initialize(rugged_repository)
      @rugged_repository = rugged_repository
    end

    # Create a new repository at a given path
    def self.create(*args)
      new Rugged::Repository.init_at(*args)
    end

    # Find a repository by its path and return an instance of Repository class
    def self.find(path)
      new Rugged::Repository.new(path)
    rescue Rugged::RepositoryError, Rugged::OSError
      # return nil if repo or path does not exist
      return nil
    end
  end
end
