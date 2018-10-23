# frozen_string_literal: true

FactoryBot.define do
  factory :file_resource do
    provider_id     0
    external_id     { Faker::Crypto.unique.sha1 }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :with_parent do
      association :parent, factory: :file_resource
    end

    trait :with_thumbnail do
      association :thumbnail, factory: :file_resource_thumbnail
    end

    trait :deleted do
      name nil
      content_version nil
      mime_type nil
      is_deleted true
    end

    trait :with_backup do
      after(:create) do |file_resource|
        create(:file_resource_backup,
               file_resource_snapshot: file_resource.current_snapshot)
        file_resource.current_snapshot.reload_backup
      end
    end
  end
end
