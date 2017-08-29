# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_file, class: VersionControl::File do
    skip_create

    name              { Faker::File.unique.file_name('', nil, nil, '') }
    collection        { build :vc_file_collection }
    content           { Faker::Lorem.paragraphs.join('\n\n') }
    oid               { Faker::Crypto.sha1 }
    revision_author   { build :user }
    revision_summary  { Faker::Simpsons.quote }
    persisted         { false }

    # persist the file to the repository and assign oid
    before(:create) do |file|
      file.collection.create(
        name: file.name,
        content: file.content,
        revision_summary: file.revision_summary,
        revision_author: file.revision_author
      )
      file.instance_variable_set :@oid, file.collection.find(file.name).oid
      file.instance_variable_set :@persisted, true
    end

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
