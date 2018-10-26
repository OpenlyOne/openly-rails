# frozen_string_literal: true

FactoryBot.define do
  factory :file_resource_thumbnail, class: 'FileResource::Thumbnail' do
    provider_id     { 0 }
    external_id     { Faker::Crypto.unique.sha1 }
    version_id      { "v#{rand(0..1000)}" }
    image do
      File.new(
        "#{Rails.root}/spec/support/fixtures/file_resource/thumbnail.png"
      )
    end
  end
end
