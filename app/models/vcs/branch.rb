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
    delegate :root, to: :files
    delegate :folders, to: :files

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
  end
end
