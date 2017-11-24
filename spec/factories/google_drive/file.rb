# frozen_string_literal: true

FactoryGirl.define do
  factory :google_drive_file, class: Google::Apis::DriveV3::File do
    transient do
      type { %w[document spreadsheet folder].sample }
    end

    id { Faker::Crypto.unique.sha1 }
    mime_type { "application/vnd.google-apps.#{type}" }
    name { Faker::File.file_name('', nil, nil, '') }

    trait :with_kind do
      kind { 'drive#file' }
    end

    trait :with_version_and_time do
      version { rand(0..1000) }
      modified_time { Time.zone.now.utc.to_datetime }
    end
  end
end
