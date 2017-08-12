# frozen_string_literal: true

module VersionControl
  # Wrapper for Rugged2 repositories (which is a wrapper for libgit2
  # (#wrapception))
  class Repository
    delegate  :bare?,
              :branches,
              :index,
              :lookup,
              :path,
              :write,
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

    # Commit the current index/stage to master
    # Return commit OID on success
    # Return false on error
    # rubocop:disable Metrics/MethodLength
    def commit(message, author)
      # Format author
      author = {
        name: author.name,
        email: author.to_param,
        time: Time.now
      }

      # Write tree object from current index/stage
      tree_oid = index.write_tree

      # Write commit to master
      Rugged::Commit.create(
        @rugged_repository,
        author: author,
        committer: author,
        message: message,
        parents: [branches['master'].try(:target)].compact,
        tree: tree_oid,
        update_ref: 'refs/heads/master'
      )
    rescue
      return false
    end
    # rubocop:enable Metrics/MethodLength

    # Reset the index/stage to the last commit on master
    def reset_index!
      index.clear
      return if branches['master'].nil?
      index.read_tree branches['master'].target.tree
    end
  end
end
