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
      lock(args[0]) do
        # raise error if repository already exists
        raise Errno::EEXIST if File.exist?(args[0])

        # create repository
        new(Rugged::Repository.init_at(*args))
      end
    end

    # Find a repository by its path and return an instance of Repository class
    def self.find(path)
      new Rugged::Repository.new(path)
    rescue Rugged::RepositoryError, Rugged::OSError
      # return nil if repo or path does not exist
      return nil
    end

    # Lock the given path or wait until it becomes available
    def self.lock(path, options = {})
      options[:timeout] ||= 10
      options[:wait]    ||= 5

      relative_path = Rails.root.join(path).relative_path_from(Rails.root).to_s
      path_to_lock = Rails.root.join(Settings.lock_storage, relative_path)

      # Create directory for lock, if it does not exist
      FileUtils.mkdir_p(path_to_lock.dirname.to_s)

      Filelock(path_to_lock, options) do
        yield
      end
    end

    # Destroy the repository
    def destroy
      lock do
        FileUtils.rm_rf workdir
      end
    end

    private

    # Create a file lock for the current instance of repository
    def lock
      self.class.lock(workdir) { yield }
    end
  end
end
