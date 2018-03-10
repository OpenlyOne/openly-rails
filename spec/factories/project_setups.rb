# frozen_string_literal: true

FactoryGirl.define do
  factory :project_setup, class: 'Project::Setup' do
    project
    is_completed false
  end
end
