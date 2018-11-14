# frozen_string_literal: true

module VCS
  # A branch of the repository
  class Branch < ApplicationRecord
    # Associations
    belongs_to :repository

    has_many :staged_files, dependent: :delete_all do
      def root
        find_by(is_root: true)
      end

      def without_root
        where(is_root: false)
      end

      def folders
        joins_staged_snapshot
          .where(
            'staged_snapshots.mime_type = ?',
            Providers::GoogleDrive::MimeType.folder
          )
      end
    end

    has_many :staged_file_snapshots,
             through: :staged_files,
             source: :current_snapshot do
               def without_root
                 where("#{StagedFile.table_name}.is_root = ?", false)
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
    delegate :root, to: :staged_files
    delegate :folders, to: :staged_files, prefix: :staged

    # Scopes
    # Return branches that have one or more staged files with the given
    # external IDs
    scope :where_staged_files_include_external_id, lambda { |external_ids|
      joins(:staged_files)
        .merge(VCS::StagedFile.joins_staged_snapshot)
        .where(vcs_staged_files: { external_id: external_ids.to_a })
        .distinct
    }
  end
end
