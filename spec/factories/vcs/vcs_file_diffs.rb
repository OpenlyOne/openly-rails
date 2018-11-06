# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_diff, class: 'VCS::FileDiff' do
    association :commit, factory: :vcs_commit
    association :new_snapshot, factory: :vcs_file_snapshot
    first_three_ancestors { Faker::Lorem.words(3) }

    trait :with_previous_snapshot do
      association :old_snapshot, factory: :vcs_file_snapshot
    end
  end
end
