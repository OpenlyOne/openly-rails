# frozen_string_literal: true

FactoryGirl.define do
  factory :file, class: VersionControl::Files::Staged do
    transient do
      id            { Faker::Crypto.unique.sha1 }
      name          { Faker::File.file_name('', nil, nil, '') }
      mime_type     { 'document' }
      parent        { nil }
      parent_id     { parent&.id || Faker::Crypto.unique.sha1 }
      version       { rand(1..1000) }
      modified_time { Time.zone.now }

      is_root       { false }
      repository do
        parent&.file_collection&.repository || build(:repository)
      end
    end

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end

    trait :root do
      folder
      is_root   { true }
      parent_id { nil }
    end

    initialize_with do
      new(
        repository.stage.files,
        id: id,
        name: name,
        parent_id: parent_id,
        mime_type: mime_type,
        version: version,
        modified_time: modified_time,
        is_root: is_root
      )
    end

    to_create do |instance|
      instance.send :create
    end
  end
end
