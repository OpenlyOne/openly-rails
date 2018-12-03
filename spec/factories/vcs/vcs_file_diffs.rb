# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_diff, class: 'VCS::FileDiff' do
    association :commit, factory: :vcs_commit
    association :new_version, factory: :vcs_version
    first_three_ancestors { Faker::Lorem.words(3) }

    trait :with_previous_version do
      association :old_version, factory: :vcs_version
    end
  end
end
