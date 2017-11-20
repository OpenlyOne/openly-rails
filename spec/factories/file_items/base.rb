# frozen_string_literal: true

FactoryGirl.define do
  factory :file_items_base, class: FileItems::Base do
    transient do
      google_apps_type { %w[document spreadsheet folder].sample }
    end

    project
    parent { nil }
    google_drive_id { Faker::Crypto.unique.sha1 }
    name { Faker::File.file_name('', nil, nil, '') }
    mime_type { "application/vnd.google-apps.#{google_apps_type}" }
  end
end
