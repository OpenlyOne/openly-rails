# frozen_string_literal: true

module VersionControl
  # A single version controlled file
  # rubocop:disable Metrics/ClassLength
  class File
    include ActiveModel::Dirty
    include ActiveModel::Validations

    # Change the route key, so that the url_for helper automatically generates
    # the right route
    # See: https://stackoverflow.com/a/13131811/6451879
    model_name.class_eval do
      def route_key
        singular_route_key.pluralize
      end

      def singular_route_key
        'file'
      end
    end

    # Define attributes to be dirty-tracked
    def self.dirty_tracked_attributes
      %i[name content revision_summary revision_author]
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
    validates :name, presence: true, on: :save
    validates :name,
              format: {
                without: %r{/},
                message: 'must not contain forward slashes (/)'
              },
              on: :save,
              if: 'name_changed?'
    validate :name_must_be_case_insensitively_unique,
             on: :save,
             if: 'name_changed?'
    validate :show_route_must_not_conflict_with_other_routes,
             on: :save,
             if: 'name_changed?',
             unless: proc { |file| file.errors[:name].any? }
    validate :must_change_content_or_name, on: :save, if: 'persisted?'
    # These validations should be last to ensure a logical order of errors
    validates :revision_author,   presence: true, on: %i[save destroy]
    validates :revision_summary,  presence: true, on: %i[save destroy]

    # Initialize a new file and commit to repository
    # Return reference to new file
    def self.create(params)
      file = new params

      # save the file
      file.save

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
        unless value == send(dirty_tracked_attribute.to_sym)
          send "#{dirty_tracked_attribute}_will_change!"
        end

        # set new value
        instance_variable_set "@#{dirty_tracked_attribute}", value
      end
    end

    # Return the file's content
    def content
      @content ||= (repository.lookup(oid).content if oid)
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

    # Return the last contribution made to this file
    def last_contribution
      @last_contribution ||=
        (VersionControl::Contribution.new(last_commit) if last_commit)
    end

    # Return true if the file is persisted
    def persisted?
      @persisted
    end

    # Save a new revision of the file
    def save
      # validate the file
      return false if invalid?(:save)

      # Write the file
      write_content_to_repository if content_changed?

      # Commit the change(s)
      commit_oid = commit do |file|
        # remove old file version if this file is already under VC
        file.repository.index.remove file.name_was if file.persisted?
        # add the file with its new name and content
        file.repository.index.add path: file.name, oid: file.oid, mode: 0o100644
      end

      # mark file as persisted & reset dirty tracking if commit succeeded
      @persisted = true if commit_oid

      commit_oid
    end

    # Attempt to save a new revision of the file
    # Raise error if unsuccessful
    def save!
      return_value = save
      raise ActiveRecord::RecordInvalid unless return_value
      return_value
    end

    # Update attributes and attempt to save a new revision of file
    def update(params = {})
      (self.class.dirty_tracked_attributes +
       self.class.accessor_attributes).each do |attribute|
        send "#{attribute}=", params[attribute] if params[attribute]
      end
      save
    end

    # Required for working with form_for
    def to_key; end

    # The model name to use when generating routes
    def to_model
      self
    end

    # Use file name when generating routes
    def to_param
      name_was
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

      # reset dirty tracking and clear revision author & summary
      if commit_id
        changes_applied
        self.revision_author = nil
        self.revision_summary = nil
      end

      commit_id
    end

    # Return the last commit on the file(Rugged::Commit)
    def last_commit
      return nil unless repository.branches['master']
      raw_commit =
        `git \
        --git-dir=#{Shellwords.escape(repository.path)} log --follow -1 \
        -- #{Shellwords.escape(name_was)}`
      return nil unless raw_commit.present?
      repository.lookup(raw_commit.split(/\s/).second)
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

    # Validate that content OR name is changed
    # rubocop:disable Style/GuardClause
    def must_change_content_or_name
      if content_changed? && name_changed?
        errors.add :base,
                   'You cannot update file content and name at the same time'
      end

      unless content_changed? || name_changed?
        errors.add :base, 'You must make at least one change to the file'
      end
    end
    # rubocop:enable Style/GuardClause

    # Validate that the new show route does not conflict with any other routes.
    # For example, with the /new(.format) route.
    def show_route_must_not_conflict_with_other_routes
      show_url = Rails.application.routes.url_helpers
                      .profile_project_file_path('user_handle', 'project', name)
      route = Rails.application.routes.recognize_path show_url
      return if route[:controller] == 'files' && route[:action] == 'show'
      errors.add :name, 'is not available'
    end
  end
  # rubocop:enable Metrics/ClassLength
end
