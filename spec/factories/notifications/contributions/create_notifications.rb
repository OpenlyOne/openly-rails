# frozen_string_literal: true

FactoryBot.define do
  factory :contributions_create_notification, parent: :notification do
    association :notifiable, factory: :contribution
    key { 'contribution.create' }
  end
end
