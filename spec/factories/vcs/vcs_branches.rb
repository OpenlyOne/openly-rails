# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_branch, class: 'VCS::Branch' do
    association :repository, factory: :vcs_repository
  end
end
