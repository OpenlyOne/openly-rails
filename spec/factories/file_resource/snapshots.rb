# frozen_string_literal: true

FactoryGirl.define do
  factory :file_resource_snapshot, class: 'FileResource::Snapshot' do
    file_resource
    external_id     { file_resource.external_id }
    name            { file_resource.name }
    content_version { file_resource.content_version }
    mime_type       { file_resource.mime_type }
    parent          { file_resource.parent }
  end
end
