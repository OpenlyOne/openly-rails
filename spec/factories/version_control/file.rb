# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_file, class: VersionControl::File do
    name              { Faker::File.unique.file_name('', nil, nil, '') }
    collection        { build :vc_file_collection }
    content           { Faker::Lorem.paragraphs.join('\n\n') }
    oid               { Faker::Crypto.sha1 }
    revision_author   { build :user }
    revision_summary  { Faker::Simpsons.quote }
    persisted         { false }

    initialize_with do
      new(
        name: name,
        collection: collection,
        oid: oid,
        content: content,
        revision_summary: revision_summary,
        revision_author: revision_author,
        persisted: persisted
      )
    end
  end
end
