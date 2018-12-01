# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_backup, class: 'VCS::FileBackup' do
    association :file_snapshot, factory: :vcs_file_snapshot
    remote_file_id { Faker::Crypto.unique.sha1 }
  end
end
