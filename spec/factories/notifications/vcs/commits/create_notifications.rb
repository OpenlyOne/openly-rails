# frozen_string_literal: true

FactoryBot.define do
  factory :vcs_commits_create_notification, parent: :notification do
    association :notifiable, factory: :vcs_commit
    key { 'revision.create' }

    after(:create) do |notification|
      create(:project, :skip_archive_setup, :setup_complete,
             repository: notification.notifiable.repository,
             master_branch: notification.notifiable.repository.branches.first)
    end
  end
end
