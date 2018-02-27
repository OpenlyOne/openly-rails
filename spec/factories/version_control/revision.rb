# frozen_string_literal: true

FactoryGirl.define do
  factory :git_revision, class: VersionControl::Revisions::Committed do
    skip_create

    transient do
      repository    { build :repository }
      title         { Faker::HarryPotter.quote }
      summary       { Faker::Lorem.paragraph }
      author        { create :user }
      author_hash   { { name: author.handle, email: author.id.to_s } }
    end

    initialize_with do
      commit =
        repository.lookup(
          repository.build_revision.commit(title, summary, author_hash)
        )
      new(repository.revisions, commit)
    end

    after(:create) do |revision|
      revision.revision_collection.reload
    end
  end
end
