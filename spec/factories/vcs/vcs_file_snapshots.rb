# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_snapshot, class: 'VCS::FileSnapshot' do
    transient do
      parent { nil }
    end

    association :file_record, factory: :vcs_file_record
    remote_file_id      { Faker::Crypto.unique.sha1 }
    file_record_parent  { parent&.file_record || create(:vcs_file_record) }
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
