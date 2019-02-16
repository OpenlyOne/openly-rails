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

    trait :commit_files do
      after(:create) do |commit|
        commit.tap(&:commit_all_files_in_branch)
              .tap(&:generate_diffs)
              .update!(is_published: true)
      end
    end
  end
end
