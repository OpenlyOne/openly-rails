module VCS
  class FileRecord < ApplicationRecord
    belongs_to :repository

    has_many :repository_branches, through: :repository, source: :branches
    has_many :staged_instances, ->(file_record) { where(file_record_id: file_record.id) },
             through: :repository_branches,
             source: :staged_files

    has_many :file_snapshots, dependent: :destroy
    has_many :file_snapshots_of_children,
             class_name: 'VCS::FileSnapshot',
             foreign_key: :file_record_parent_id,
             dependent: :destroy
  end
end
