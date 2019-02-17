# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_commit_notification, parent: :notification do
    association :notifiable, factory: :vcs_commit

    after(:create) do |notification|
      create(:project, :skip_archive_setup, :setup_complete,
             repository: notification.notifiable.repository,
             master_branch: notification.notifiable.repository.branches.first)
    end
  end
end
