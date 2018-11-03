FactoryBot.define do
  factory :vcs_staged_file, class: 'VCS::StagedFile' do
    transient do
      parent { nil }
      repository do
        parent&.branch&.repository ||
          branch&.repository ||
          create(:vcs_repository)
      end
    end

    with_parent

    branch          { parent&.branch || create(:vcs_branch) }
    file_record     { create(:vcs_file_record, repository: repository) }
    external_id     { Faker::Crypto.unique.sha1 }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }
    is_root         { false }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :with_parent do
      file_record_parent { parent&.file_record || create(:vcs_file_record) }
    end

    trait :root do
      is_root { true }
      folder
      file_record_parent_id { nil }
    end

    trait :with_thumbnail do
      association :thumbnail, factory: :vcs_file_thumbnail
    end

    trait :deleted do
      name { nil }
      content_version { nil }
      mime_type { nil }
      is_deleted { true }
    end

    trait :with_snapshots do
      current_snapshot { create(:vcs_file_snapshot, mime_type: mime_type) }
      committed_snapshot { create(:vcs_file_snapshot, mime_type: mime_type) }
    end

    trait :unchanged do
      with_snapshots
      committed_snapshot { current_snapshot }
    end

    trait :with_backup do
      after(:create) do |staged_file|
        create(:vcs_file_backup, file_snapshot: staged_file.current_snapshot)
        staged_file.current_snapshot.reload_backup
      end
    end
  end
end
