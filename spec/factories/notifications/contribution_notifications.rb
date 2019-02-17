# frozen_string_literal: true

FactoryBot.define do
  factory :contribution_notification, parent: :notification do
    association :notifiable, factory: :contribution
  end
end
