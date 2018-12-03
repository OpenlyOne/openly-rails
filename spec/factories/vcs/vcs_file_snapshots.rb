# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_snapshot, class: 'VCS::FileSnapshot' do
    transient do
      parent_in_branch { nil }
    end

    association :file, factory: :vcs_file
    remote_file_id      { Faker::Crypto.unique.sha1 }
    parent              { parent_in_branch&.file || create(:vcs_file) }
    name                { Faker::File.file_name('', nil, nil, '') }
    content_version     { rand(1..1000) }
    mime_type           { 'application/vnd.google-apps.document' }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :pdf do
      mime_type { Providers::GoogleDrive::MimeType.pdf }
    end

    trait :with_backup do
      backup do
        build(:vcs_file_backup,
              file_snapshot: VCS::FileSnapshot.new)
      end
    end

    after(:build) do |snapshot|
      snapshot.content =
        VCS::Operations::ContentGenerator.generate(
          repository: snapshot.repository,
          remote_file_id: snapshot.remote_file_id,
          remote_content_version_id: snapshot.content_version
        )
    end
  end
end
