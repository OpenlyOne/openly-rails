# frozen_string_literal: true

module VersionControl
  # Wrapper for Rugged2 repositories (which is a wrapper for libgit2
  # (#wrapception))
  class Repository
    attr_reader :rugged_repository

    delegate :bare?, :lookup, :path, to: :rugged_repository

    # Create a new instance with a Rugged::Repository repo
    def initialize(rugged_repository)
      @rugged_repository = rugged_repository
    end

    # Create a new repository at a given path
    def self.create(*args)
      lock(args[0]) do
        # raise error if repository already exists
        raise Errno::EEXIST if ::File.exist?(args[0])

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

    # Build a new revision draft, either based on the passed tree id or by
    # saving the files in working directory
    def build_revision(tree_id = nil)
      lock do
        # Save files in working directory if we're building a revision without
        # having an existing tree id
        tree_id ||= stage.save

        # Initialize the revision draft and return
        Revisions::Drafted.new(self, tree_id)
      end
    end

    # Destroy the repository
    def destroy
      lock do
        FileUtils.rm_rf workdir
      end
    end

    # Create a file lock for the current instance of repository
    def lock
      return yield if has_lock

      self.class.lock(workdir) do
        begin
          self.has_lock = true
          return yield()
        ensure
          self.has_lock = false
        end
      end
    end

    # A collection of this repository's revisions
    def revisions
      @revisions ||= RevisionCollection.new(self)
    end

    # The repository's stage / index / working directory
    def stage
      @stage ||= Revisions::Staged.new(self)
    end

    # Return the clean path for the repository's working directory
    def workdir
      return nil unless @rugged_repository&.workdir
      Pathname(@rugged_repository.workdir).cleanpath.to_s
    end

    private

    attr_accessor :has_lock
  end
end
