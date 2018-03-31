# frozen_string_literal: true

FactoryBot.define do
  factory :staged_file_diff, class: Stage::FileDiff do
    project
    association :staged_snapshot, factory: :file_resource_snapshot
    association :committed_snapshot, factory: :file_resource_snapshot
  end
end
