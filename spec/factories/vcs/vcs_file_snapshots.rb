FactoryBot.define do
  factory :vcs_file_snapshot, class: 'VCS::FileSnapshot' do
    transient do
      parent { nil }
    end

    association :file_record, factory: :vcs_file_record
    external_id         { Faker::Crypto.unique.sha1 }
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
        build(:file_resource_backup,
              file_resource_snapshot: FileResource::Snapshot.new)
      end
    end
  end
end
