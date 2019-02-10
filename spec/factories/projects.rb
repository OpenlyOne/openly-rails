# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    transient do
      owner_account_email { nil }
    end

    sequence(:title) do |n|
      "#{n} #{Faker::HitchhikersGuideToTheGalaxy.starship}".first(50).strip
    end
    description     { Faker::Lorem.paragraph }
    tags            { Faker::Lorem.words }
    sequence(:slug) { |n| "project-slug-#{n}" }
    owner           { build(:user, account_email: owner_account_email) }
    is_public       { false }
    are_contributions_enabled { true }
    captured_at { Faker::Time.between(DateTime.now - 7, DateTime.now) }

    trait :public do
      is_public { true }
    end

    trait :private do
      is_public { false }
    end

    trait :setup_complete do
      after(:create) do |project|
        create(:project_setup, :completed, project: project)
      end
    end

    trait :skip_archive_setup do
      skip_archive_setup { true }
    end

    trait :with_repository do
      association :master_branch, factory: :vcs_branch
      repository { master_branch.repository }
    end
  end
end
