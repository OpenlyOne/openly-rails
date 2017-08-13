# frozen_string_literal: true

FactoryGirl.define do
  factory :vc_file, class: VersionControl::File do
    skip_create

    transient do
      content     { Faker::Lorem.paragraphs.join('\n\n') }
      message     { Faker::Simpsons.quote }
      author      { build :user }
    end

    name          { Faker::File.unique.file_name('', nil, nil, '') }
    collection    { build :vc_file_collection }
    oid           { Faker::Crypto.sha1 }

    # persist the file to the repository and assign oid
    before(:create) do |file, transient|
      file.collection.create(
        file.name,
        transient.content,
        transient.message,
        transient.author
      )
      file.instance_variable_set :@oid, file.collection.find(file.name).oid
    end

    initialize_with { new name: name, collection: collection, oid: oid }
  end
end
