# frozen_string_literal: true

module VCS
  # A branch of the repository
  class Branch < ApplicationRecord
    # Associations
    belongs_to :repository

    has_many :files, class_name: 'FileInBranch', dependent: :delete_all do
      def root
        find_by(is_root: true)
      end

      def without_root
        where(is_root: false)
      end

      def folders
        joins_version
          .where(
            'versions.mime_type = ?',
            Providers::GoogleDrive::MimeType.folder
          )
      end
    end

    has_many :versions_in_branch,
             through: :files,
             source: :current_version do
               def without_root
                 where("#{VCS::FileInBranch.table_name}.is_root = ?", false)
               end
             end

    has_many :all_commits, class_name: 'VCS::Commit', dependent: :destroy
    has_many :commits, -> { published } do
      def create_draft_and_commit_files!(author)
        Commit.create_draft_and_commit_files_for_branch!(
          proxy_association.owner,
          author
        )
      end
    end

    # Delegations
    delegate :folders, :root, to: :files
    delegate :archive, :branches, :files, to: :repository, prefix: true
    delegate :remote_file_id, to: :repository_archive, prefix: :archive

    # Scopes
    # Return branches that have one or more files with the given remote IDs
    scope :where_files_include_remote_file_id, lambda { |remote_file_ids|
      joins(:files)
        .merge(VCS::FileInBranch.joins_version)
        .where(
          "#{VCS::FileInBranch.table_name}": {
            remote_file_id: remote_file_ids.to_a
          }
        ).distinct
    }

    # Create a root folder for this branch remotely and locally
    # TODO: Refactor with #push method and reduce complexity
    # rubocop:disable Metrics/MethodLength
    def create_remote_root_folder(remote_parent_id:)
      return false if root.present?

      # Create remote
      root_folder = sync_adapter_class.create(
        name: "Branch ##{id}",
        parent_id: remote_parent_id,
        mime_type: mime_type_class.folder
      )

      # Create local
      files.build(
        remote_file_id: root_folder.id,
        is_root: true,
        file: repository_files.root
      ).tap(&:pull)
    end
    # rubocop:enable Metrics/MethodLength

    # Copy all committed files from branch over to this branch
    # All new files are marked as deleted
    def copy_committed_files_from(branch_to_copy_from)
      branch_to_copy_from.files.committed.find_each do |file_in_branch|
        files.create!(
          file_id: file_in_branch.file_id,
          committed_version_id: file_in_branch.committed_version_id,
          is_deleted: true
        )
      end
    end

    # Fork this branch
    # TODO: Author should be extracted out of this operation. It is
    # =>    not needed. But we need to remove the not null constraint from the
    # =>    database (which we need to do anyway to make it possible for
    # =>    users to delete their accounts).
    def create_fork(creator:, remote_parent_id:)
      repository_branches.create!.tap do |fork|
        fork.create_remote_root_folder(remote_parent_id: remote_parent_id)
        fork.copy_committed_files_from(self)
        fork.restore_commit(commits.last, author: creator)
      end
    end

    # Copy files from specified commit to stage
    # TODO: Author should be extracted out of this operation. It is
    # =>    not needed. But we need to remove the not null constraint from the
    # =>    database (which we need to do anyway to make it possible for
    # =>    users to delete their accounts).
    def restore_commit(commit, author:)
      VCS::Operations::CommitRestore.restore(
        commit: commit,
        target_branch: self,
        author: author
      )
    end

    # Update the count of files with uncaptured changes in this branch
    def update_uncaptured_changes_count
      update_attribute(
        :uncaptured_changes_count,
        files.without_root.where_change_is_uncaptured.count
      )
    end

    private

    def mime_type_class
      "Providers::#{provider}::MimeType".constantize
    end

    def provider
      'GoogleDrive'
    end

    def sync_adapter_class
      "Providers::#{provider}::FileSync".constantize
    end
  end
end
