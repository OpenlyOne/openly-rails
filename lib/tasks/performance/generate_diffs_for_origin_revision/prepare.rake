# frozen_string_literal: true

desc 'Performance: Generate diffs for origin revision: Prepare'
namespace :performance do
  namespace :generate_diffs_for_origin_revision do
    task prepare: :test_environment do
      puts 'Preparing database'

      snapshot_id = FactoryBot.create(:file_resource_snapshot).id
      batch_size = 1_000
      columns = %i[provider_id external_id mime_type name content_version
                   current_snapshot_id]

      10.times do |n|
        rows = []
        batch_size.times do |batch_n|
          rows << [0, (batch_n + batch_size * n).to_s, 'doc', 'name', '1',
                   snapshot_id]
        end
        FileResource.import columns, rows, validate: false
        puts "Progress: #{(n + 1) * batch_size} records created"
      end

      puts 'Creating revision with all file resources committed'
      revision = FactoryBot.create(:revision)

      columns = %i[file_resource_id file_resource_snapshot_id revision_id]
      rows = FileResource.all.pluck(:id, :current_snapshot_id)
                         .map { |v| v.push(revision.id) }
      CommittedFile.import columns, rows, validate: false

      puts 'Preparing database...Done'
    end
  end
end
