# frozen_string_literal: true

FactoryGirl.define do
  factory :google_drive_file, class: Google::Apis::DriveV3::File do
    transient do
      type { %w[document spreadsheet folder].sample }
    end

    id { Faker::Crypto.unique.sha1 }
    kind { 'drive#file' }
    mime_type { "application/vnd.google-apps.#{type}" }
    name { Faker::File.file_name('', nil, nil, '') }
  end
end
