# frozen_string_literal: true

FactoryGirl.define do
  factory :file_resource do
    provider_id     0
    external_id     { Faker::Crypto.unique.sha1 }
    name            { Faker::File.file_name('', nil, nil, '') }
    content_version { rand(1..1000) }
    mime_type       { 'application/vnd.google-apps.document' }

    trait :with_parent do
      association :parent, factory: :file_resource
    end
  end
end
