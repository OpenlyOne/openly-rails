module VCS
  class Branch < ApplicationRecord
    belongs_to :repository

    has_many :staged_files, dependent: :delete_all do
      def root
        find_by(is_root: true)
      end

      def folders
        joins_staged_snapshot
          .where(
            'staged_snapshots.mime_type = ?',
            Providers::GoogleDrive::MimeType.folder
          )
      end
    end

    delegate :root, to: :staged_files
    delegate :folders, to: :staged_files, prefix: :staged

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
  end
end
