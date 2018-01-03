# frozen_string_literal: true

FactoryGirl.define do
  factory :committed_file,
          class: VersionControl::Files::Committed,
          parent: :file do
    skip_create

    initialize_with do
      create :revision, repository: repository
      new(
        repository.revisions.last.files,
        id: id,
        name: name,
        parent_id: parent_id,
        mime_type: mime_type,
        version: version,
        modified_time: modified_time,
        is_root: is_root
      )
    end
  end
end
