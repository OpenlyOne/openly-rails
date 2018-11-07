# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_remote_content, class: 'VCS::RemoteContent' do
    association :content, factory: :vcs_content
    repository                { content.repository }
    remote_file_id            { Faker::Crypto.unique.sha1 }
    remote_content_version_id { Faker::Crypto.sha1.first(4) }
  end
end
