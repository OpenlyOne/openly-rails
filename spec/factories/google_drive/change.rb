# frozen_string_literal: true

FactoryBot.define do
  factory :google_drive_change, class: Google::Apis::DriveV3::Change do
    transient do
      id            { Faker::Crypto.unique.sha1 }
      name          { Faker::File.file_name('', nil, nil, '') }
      parent        { Faker::Crypto.unique.sha1 }
      version       { rand(0..1000) }
      trashed       { false }
      parents       { parent.present? ? [parent] : nil }
      modified_time { Time.zone.now.utc }
      file_type     { %w[document spreadsheet folder].sample }
      mime_type     { "application/vnd.google-apps.#{file_type}" }
    end

    file_id { id }
    type { 'file' }
    removed { false }

    trait :with_file do
      file do
        build :google_drive_file,
              :with_version_and_time,
              name: name,
              mime_type: mime_type,
              version: version,
              trashed: trashed,
              parents: parents,
              modified_time: modified_time
      end
    end
  end
end
