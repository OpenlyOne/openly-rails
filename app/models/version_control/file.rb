# frozen_string_literal: true

module VersionControl
  # A single version controlled file
  class File
    include ActiveModel::Validations

    attr_accessor :name, :collection, :content,
                  :revision_summary, :revision_author
    attr_reader   :oid

    delegate :repository, to: :collection

    # Validations
    validates :revision_author,   presence: true, on: :create
    validates :revision_summary,  presence: true, on: :create
    validates :name,              presence: true, on: :create
    validates :name,
              format: {
                without: %r{/},
                message: 'must not contain forward slashes (/)'
              },
              on: :create
    validate :name_must_be_case_insensitively_unique, on: :create

    # Initialize a new file and commit to repository
    # Return reference to new file
    def self.create(params)
      file = new params

      # validate the file
      return false if file.invalid?

      # save the file
      file.write_content_to_repository
      file.send :commit do |f|
        f.repository.index.add path: f.name, oid: f.oid, mode: 0o100644
      end
      file.instance_variable_set :@persisted, true

      # return the file instance
      file
    end

    def initialize(params = {})
      @oid                = params[:oid]
      @name               = params[:name]
      @collection         = params[:collection]
      @content            = params[:content]
      @revision_summary   = params[:revision_summary]
      @revision_author    = params[:revision_author]
      @persisted          = params[:persisted] || false
    end

    # Return the file's content
    def content
      @content ||= repository.lookup(oid).content
    end

    # Return true if the file is persisted
    def persisted?
      @persisted
    end

    # Write the content to a new blob in repository
    def write_content_to_repository
      @oid = repository.write content, :blob
    end

    private

    # Wrapper for actions that are identical for commits
    def commit
      # remove file from index/stage and commit
      repository.reset_index!

      # execute block
      yield self

      # make a commit
      commit_id = repository.commit revision_summary, revision_author

      # clear revision author & summary
      if commit_id
        self.revision_author = nil
        self.revision_summary = nil
      end

      commit_id
    end

    # Validate that the name is case sensitively unique within the version
    # controlled repository
    # rubocop:disable Style/GuardClause
    def name_must_be_case_insensitively_unique
      if collection.reload!.exists?(name)
        errors.add :name, 'has already been taken'
      end
    end
    # rubocop:enable Style/GuardClause
  end
end
