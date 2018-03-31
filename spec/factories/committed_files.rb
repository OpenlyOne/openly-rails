# frozen_string_literal: true

FactoryBot.define do
  factory :committed_file do
    revision
    file_resource
    file_resource_snapshot { file_resource.current_snapshot }
  end
end
