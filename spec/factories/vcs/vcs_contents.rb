# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_content, class: 'VCS::Content' do
    association :repository, factory: :vcs_repository
  end
end
