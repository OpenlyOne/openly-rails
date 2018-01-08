# frozen_string_literal: true

FactoryGirl.define do
  factory :revision, class: VersionControl::Revisions::Committed do
    skip_create

    transient do
      repository    { build :repository }
      summary       { Faker::HarryPotter.quote }
      author_name   { Faker::Name.name }
      author_email  { "#{author_name.to_param}@example.com" }
      author        { { name: author_name, email: author_email } }
    end

    initialize_with do
      commit =
        repository.lookup(
          repository.build_revision.commit(summary, author)
        )
      new(repository.revisions, commit)
    end
  end
end
