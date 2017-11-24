# frozen_string_literal: true

FactoryGirl.define do
  factory :google_drive_change, class: Google::Apis::DriveV3::Change do
    transient do
      id      { Faker::Crypto.unique.sha1 }
      name    { Faker::File.file_name('', nil, nil, '') }
      parent  { Faker::Crypto.unique.sha1 }
      version { rand(0..1000) }
    end

    file_id { id }
    type { 'file' }
    removed { false }
    file do
      Google::Apis::DriveV3::File.new(
        name: name,
        version: version,
        trashed: false,
        parents: [parent]
      )
    end
  end
end
