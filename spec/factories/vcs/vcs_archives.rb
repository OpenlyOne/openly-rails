FactoryBot.define do
  factory :vcs_archive, class: 'VCS::Archive' do
    association :repository, factory: :vcs_repository
    external_id { Faker::Crypto.unique.sha1 }
  end
end
