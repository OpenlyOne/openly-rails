# frozen_string_literal: true

FactoryBot.define do
  factory :project_archive, class: 'Project::Archive' do
    project
    file_resource
  end
end
