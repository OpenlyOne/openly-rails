# frozen_string_literal: true

FactoryGirl.define do
  factory :project_setup, class: 'Project::Setup' do
    project
    is_completed false
    link { file_resource.external_link }

    transient do
      file_resource { create :file_resource, :folder }
    end
  end
end
