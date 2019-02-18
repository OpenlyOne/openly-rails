# frozen_string_literal: true

FactoryBot.define do
  factory :replies_create_notification, parent: :notification do
    association :notifiable, factory: :reply
    key { 'reply.create' }
  end
end
