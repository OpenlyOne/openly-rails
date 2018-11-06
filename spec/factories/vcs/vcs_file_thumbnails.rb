# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_thumbnail, class: 'VCS::FileThumbnail' do
    external_id { Faker::Crypto.unique.sha1 }
    version_id  { "v#{rand(0..1000)}" }
    image do
      File.new(
        "#{Rails.root}/spec/support/fixtures/file_resource/thumbnail.png"
      )
    end
  end
end
