# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_committed_file, class: 'VCS::CommittedFile' do
    transient do
      parent { nil }
    end

    association :commit, factory: :vcs_commit
    file_snapshot { create(:vcs_file_snapshot, parent_in_branch: parent) }
  end
end
