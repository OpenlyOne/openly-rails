# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_base, class: FileItems::Base do
    transient do
      google_apps_type { %w[document spreadsheet presentation].sample }
    end

    project
    parent { nil }
    google_drive_id { Faker::Crypto.unique.sha1 }
    name { Faker::File.file_name('', nil, nil, '') }
    mime_type { "application/vnd.google-apps.#{google_apps_type}" }
    version { rand(1..1000) }
    modified_time { Time.zone.now.utc }

    trait :committed do
      version_at_last_commit { version }
      modified_time_at_last_commit { modified_time }
      parent_id_at_last_commit { parent&.id }
    end
  end
end
