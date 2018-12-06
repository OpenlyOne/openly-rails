# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_committed_file, class: 'VCS::CommittedFile' do
    transient do
      parent { nil }
    end

    association :commit, factory: :vcs_commit
    version { create(:vcs_version, parent_in_branch: parent) }
  end
end
