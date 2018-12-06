# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file, class: 'VCS::File' do
    association :repository, factory: :vcs_repository
  end
end
