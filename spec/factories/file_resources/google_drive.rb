# frozen_string_literal: true

FactoryGirl.define do
  factory :file_resources_google_drive,
          class: FileResources::GoogleDrive,
          parent: :file_resource do
  end
end
