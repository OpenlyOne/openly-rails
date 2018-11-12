# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :target, factory: :account
    association :notifier, factory: :user
    association :notifiable, factory: :vcs_commit
    key { 'revision.default' }

    after(:create) do |notification|
      create(:project, :skip_archive_setup, :setup_complete,
             repository: notification.notifiable.repository,
             master_branch: notification.notifiable.repository.branches.first)
    end
  end
end
