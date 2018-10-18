# frozen_string_literal: true

FactoryBot.define do
  factory :file_resource_backup, class: 'FileResource::Backup' do
    file_resource_snapshot
    association :archive, factory: :project_archive
    file_resource
  end
end
