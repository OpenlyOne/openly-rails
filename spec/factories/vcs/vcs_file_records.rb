# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_file_record, class: 'VCS::FileRecord' do
    association :repository, factory: :vcs_repository
  end
end
