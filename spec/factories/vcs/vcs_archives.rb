FactoryBot.define do
  factory :vcs_archive, class: 'VCS::Archive' do
    association :repository, factory: :vcs_repository
  end
end
