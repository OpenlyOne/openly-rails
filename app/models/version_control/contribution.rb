# frozen_string_literal: true

module VersionControl
  # A contribution (commit) to a repository
  class Contribution
    delegate :oid,
             :message,
             to: :@rugged_commit

    # Create a new instance
    def initialize(rugged_commit)
      @rugged_commit = rugged_commit
      return if @rugged_commit.is_a?(Rugged::Commit)
      raise 'VersionControl::Contribution must initialized with a ' \
            'Rugged::Commit instance'
    end

    # Return the timestamp of the contribution
    def created_at
      @created_at ||= @rugged_commit.time.utc
    end

    # Return the author of the contribution
    def author
      @author ||=
        Profiles::User.find_by(handle: author_handle)
    end

    private

    # Return the handle of the author (saved as email in Git)
    def author_handle
      @rugged_commit.author[:email]
    end
  end
end
