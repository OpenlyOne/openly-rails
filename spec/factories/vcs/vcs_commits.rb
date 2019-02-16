# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_commit, class: 'VCS::Commit' do
    author
    association :branch, factory: :vcs_branch
    title         { Faker::HarryPotter.quote }
    summary       { Faker::Lorem.paragraph }
    is_published  { false }

    trait :drafted do
      is_published { false }
    end

    trait :published do
      is_published { true }
    end

    trait :with_parent do
      parent { create(:vcs_commit, branch: branch) }
    end
  end
end
