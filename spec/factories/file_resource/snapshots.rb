# frozen_string_literal: true

FactoryBot.define do
  factory :file_resource_snapshot, class: 'FileResource::Snapshot' do
    file_resource
    external_id     { file_resource.external_id }
    parent          { file_resource.parent }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }

    trait :folder do
      mime_type { 'application/vnd.google-apps.folder' }
    end
  end
end
