# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_in_branch, class: 'VCS::FileInBranch' do
    transient do
      parent_in_branch { nil }
      repository do
        parent_in_branch&.branch&.repository ||
          branch&.repository ||
          create(:vcs_repository)
      end
    end

    with_parent

    branch          { parent_in_branch&.branch || create(:vcs_branch) }
    file            { create(:vcs_file, repository: repository) }
    remote_file_id  { Faker::Crypto.unique.sha1 }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }
    is_root         { false }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :with_parent do
      parent { parent_in_branch&.file || create(:vcs_file) }
    end

    trait :root do
      is_root { true }
      folder
      parent_id { nil }
    end

    trait :with_thumbnail do
      thumbnail { create :vcs_file_thumbnail, file_id: file_id }
    end

    trait :deleted do
      name { nil }
      content_version { nil }
      mime_type { nil }
      is_deleted { true }
    end

    trait :with_versions do
      current_version { create(:vcs_version, mime_type: mime_type) }
      committed_version { create(:vcs_version, mime_type: mime_type) }
    end

    trait :unchanged do
      with_versions
      committed_version { current_version }
    end

    trait :with_backup do
      after(:create) do |file_in_branch|
        create(:vcs_file_backup, file_version: file_in_branch.current_version)
        file_in_branch.current_version.reload_backup
      end
    end
  end
end
