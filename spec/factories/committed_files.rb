# frozen_string_literal: true

FactoryBot.define do
  factory :committed_file do
    transient do
      parent { nil }
    end

    revision
    file_resource { create(:file_resource, parent: parent) }
    file_resource_snapshot { file_resource.current_snapshot }

    after(:stub) do |committed_file|
      committed_file.file_resource_snapshot =
        build_stubbed(:file_resource_snapshot,
                      file_resource: committed_file.file_resource)
    end
  end
end
