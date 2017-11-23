# frozen_string_literal: true

FactoryGirl.define do
  factory :google_drive_channel, class: Google::Apis::DriveV3::Channel do
    transient do
      file_id { Faker::Crypto.unique.sha1 }
    end

    id { "channel-#{file_id}" }
    kind { 'api#channel' }
    resource_id { Faker::Crypto.md5 }
    resource_uri do
      "https://www.googleapis.com/drive/v3/files/#{file_id}"\
      '?acknowledgeAbuse=false&supportsTeamDrives=false&alt=json'
    end
    expiration do
      (Time.zone.now + Settings.google_drive_channel_duration)
        .to_datetime.strftime('%Q').to_i
    end
  end
end
