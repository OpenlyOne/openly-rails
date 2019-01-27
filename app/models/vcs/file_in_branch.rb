# frozen_string_literal: true

module VCS
  # An instance of a VCS::File in a branch
  # rubocop:disable Metrics/ClassLength
  class FileInBranch < ApplicationRecord
    belongs_to :branch
    has_one :repository, through: :branch
    belongs_to :file
    belongs_to :parent, class_name: 'File', optional: true

    belongs_to :committed_version, class_name: 'VCS::Version', optional: true
    belongs_to :current_version, class_name: 'VCS::Version', optional: true

    include VCS::Resourceable
    include VCS::Versionable
    # include Stageable
    include VCS::Syncable
    # must not be before VCS::Versionable, so that backup is made after
    # version is persisted
    include VCS::Backupable
    include VCS::Downloadable

    scope :joins_version, lambda {
      joins(
        'INNER JOIN vcs_versions versions ' \
        "ON (COALESCE(#{table_name}.current_version_id, "\
                     "#{table_name}.committed_version_id) "\
        '= versions.id)'
      )
    }

    # TODO: Move to a different class
    # for this model, add joins_version
    scope :order_by_name_with_folders_first, lambda { |table: nil|
      folder_mime_type = Providers::GoogleDrive::MimeType.folder
      table ||= 'versions'

      order(
        Arel.sql(
          <<~SQL
            #{table}.mime_type IN (#{connection.quote(folder_mime_type)}) desc,
            #{table}.name asc
          SQL
        )
      )
    }

    # Return only files in branch that have been committed
    scope :committed, -> { where('committed_version_id IS NOT NULL') }

    # Validations
    validates :remote_file_id, uniqueness: { scope: :branch_id },
                               if: :will_save_change_to_remote_file_id?

    # Only perform validation if no errors have been encountered
    with_options unless: :any_errors? do
      validate :cannot_be_its_own_parent
      validate :cannot_be_its_own_ancestor,
               if: :will_save_change_to_parent_id?
    end

    # Require presence of metadata unless file resource is deleted
    with_options unless: :deleted? do
      validates :remote_file_id, presence: true
      # TODO: Refactor. Must use if: :not_root? because unless: :root? would
      # => overwrite top level condition.
      # See: https://stackoverflow.com/a/15388137/6451879
      validates :parent_id, presence: true, if: :not_root?
      validates :name, presence: true
      validates :mime_type, presence: true
      validates :content_version, presence: true
    end

    # Find file in branch by hashed file ID
    # Raises ActiveRecord::RecordNotFound error if no match is found.
    def self.find_by_hashed_file_id!(id)
      find_by!(file_id: VCS::File.hashid_to_id(id))
    end

    # Find file in branch by hashed file ID,
    # or - as a fallback - by remote file ID
    # Raises ActiveRecord::RecordNotFound error if no match is found.
    def self.find_by_hashed_file_id_or_remote_file_id!(id)
      find_by_hashed_file_id!(id)
    rescue ActiveRecord::RecordNotFound
      find_by!(remote_file_id: id)
    end

    # Recursively collect parents
    def ancestors
      return [] if parent_in_branch.nil? || parent_in_branch.root?

      [parent_in_branch.version] + parent_in_branch.ancestors
    end

    # Recursively collect ids of parents
    def ancestors_ids
      ancestors.map(&:file_id)
    end

    def children
      @children ||=
        branch
        .files
        .joins_version
        .where('versions.parent_id = ?', file_id)
    end

    def children_in_branch=(new_children)
      new_children.each { |child| child.update(parent_in_branch: self) }

      children_in_branch.where.not(id: new_children.map(&:id)).find_each(&:pull)

      # Clear children because they are no longer accurate, as children in
      # branch have changed and status of committed children is unclear
      @children = nil
    end

    def children_in_branch
      branch
        .files
        .joins(:current_version)
        .where(
          "#{VCS::Version.table_name}": {
            parent_id: file_id
          }
        )
    end

    # Return the content ID for the remote file ID & remote content version
    def content_id
      return nil unless remote_file_id.present?

      VCS::Operations::ContentGenerator.generate(
        repository: repository,
        remote_file_id: remote_file_id,
        remote_content_version_id: content_version
      )&.id
    end

    # Return the link to the remote resource
    def link_to_remote
      return nil unless remote_file_id.present?

      provider_link_class.for(
        remote_file_id: remote_file_id,
        mime_type: mime_type
      )
    end

    def parent_in_branch
      @parent_in_branch ||=
        branch
        .files
        .joins_version
        .find_by('versions.file_id = ?',
                 version&.parent_id)
    end

    def parent_in_branch=(new_parent_in_branch)
      if new_parent_in_branch.present?
        self.parent_id = new_parent_in_branch.file_id
        @parent_in_branch = new_parent_in_branch
      else
        mark_as_removed unless root?
      end
    end

    # TODO: Rename is_deleted to is_removed
    def mark_as_removed
      assign_attributes(
        parent_id: nil, name: nil, mime_type: nil,
        content_version: nil, is_deleted: true
      )
    end

    def version
      current_version || committed_version
    end

    def diff(with_ancestry: false)
      @diff ||=
        VCS::FileDiff.new.tap do |diff|
          diff.new_version_id = current_version_id
          diff.old_version_id = committed_version_id
          # TODO: Add depth option for ancestry. Should be max 3
          diff.first_three_ancestors = ancestors.map(&:name) if with_ancestry
        end
    end

    def deleted?
      is_deleted
    end

    # TODO: Don't use mime type on file in branch, but on version instead
    def folder?
      Object.const_get("#{provider}::MimeType").folder?(mime_type)
    end

    # Return the hashed ID of the file ID
    def hashed_file_id
      VCS::File.id_to_hashid(file_id)
    end

    def root?
      is_root
    end

    def not_root?
      !root?
    end

    # Return all children that are folders
    def subfolders
      children_in_branch.select(&:folder?)
    end

    # When parameterizing this resource, return the hashed file ID
    def to_param
      hashed_file_id
    end

    private

    def any_errors?
      errors.any?
    end

    def cannot_be_its_own_ancestor
      return unless ancestors_ids.include? file_id

      errors.add(:base, 'Staged file cannot be its own ancestor')
    end

    def cannot_be_its_own_parent
      # check if IDs match
      return unless file_id == parent_id
      # both IDs are the same or they are both nil. This could mean that file is
      # its own parent, or it could mean that both records are new, so lets
      # check the actual instances
      return unless file == parent

      errors.add(:base, 'Staged file cannot be its own parent')
    end
    # rubocop:enable Metrics/ClassLength
  end
end
