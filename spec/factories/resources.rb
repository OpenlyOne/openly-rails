# frozen_string_literal: true

FactoryBot.define do
  factory :resource do
    title       { Faker::File.file_name('', nil, nil, '') }
    description { Faker::Lorem.paragraph }
    mime_type   { 'application/vnd.google-apps.document' }
    association :owner, factory: :user
    link        { Faker::Internet.url('drive.google.com') }
  end
end
