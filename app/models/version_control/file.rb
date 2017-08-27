# frozen_string_literal: true

module VersionControl
  # A single version controlled file
  class File
    include ActiveModel::Dirty
    include ActiveModel::Validations

    # Define attributes to be dirty-tracked
    def self.dirty_tracked_attributes
      %i[name content revision_author revision_summary]
    end

    # Define attributes to be read and set
    def self.accessor_attributes
      %i[collection]
    end

    # Define attributes to be read only
    def self.reader_attributes
      %i[oid]
    end

    define_attribute_methods(*dirty_tracked_attributes)
    attr_accessor(*accessor_attributes)
    attr_reader(*(reader_attributes + dirty_tracked_attributes))

    delegate :repository, to: :collection

    # Validations
    validates :revision_author,   presence: true, on: %i[create destroy]
    validates :revision_summary,  presence: true, on: %i[create destroy]
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

    # rubocop:disable Metrics/AbcSize
    def initialize(params = {})
      (self.class.dirty_tracked_attributes +
       self.class.accessor_attributes).each do |attribute|
        send "#{attribute}=", params[attribute]
      end
      self.class.reader_attributes.each do |reader_attribute|
        instance_variable_set "@#{reader_attribute}", params[reader_attribute]
      end
      @persisted = params[:persisted] || false

      # if file is persisted: do not mark values set by initialization as dirty
      clear_changes_information if persisted?
    end
    # rubocop:enable Metrics/AbcSize

    # Dirty-tracked attribute setters
    dirty_tracked_attributes.each do |dirty_tracked_attribute|
      define_method "#{dirty_tracked_attribute}=" do |value|
        # attr_will_change unless value does not change
        unless value == instance_variable_get("@#{dirty_tracked_attribute}")
          send "#{dirty_tracked_attribute}_will_change!"
        end

        # set new value
        instance_variable_set "@#{dirty_tracked_attribute}", value
      end
    end

    # Return the file's content
    def content
      @content ||= repository.lookup(oid).content
    end

    # Destroy the file
    def destroy
      # do not destroy unless the file is persisted
      raise ActiveRecord::Rollback unless persisted?

      # reset all values other than revision author and summary
      restore_name!
      restore_content!

      # validate that revision is valid
      return false unless valid?(:destroy)

      # Commit the change(s)
      commit_oid = commit do |file|
        file.repository.index.remove file.name_was
      end

      # file is no longer persisted
      @persisted = false if commit_oid

      commit_oid
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
        changes_applied
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
