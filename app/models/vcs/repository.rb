module VCS
  class Repository < ApplicationRecord
    has_many :branches, dependent: :destroy

    has_one :archive, dependent: :destroy
    has_many :file_records, dependent: :destroy
    has_many :file_snapshots, through: :file_records
    has_many :file_backups, through: :file_snapshots, source: :backup
  end
end
