# frozen_string_literal: true

desc 'Performance: Generate diffs for revision with parent: Prepare'
namespace :performance do
  namespace :generate_diffs_for_revision_with_parent do
    task prepare: :test_environment do
      puts 'Preparing database'

      create_file_resources

      puts 'Creating revision with all file resources committed'
      create_revision_with_all_file_resources_committed

      puts 'Updating 100 file resources'
      FileResource.first(100).each do |file|
        file.update(name: 'updated')
      end

      puts 'Creating 2nd revision with all file resources committed'
      create_revision_with_all_file_resources_committed(parent: Revision.last)

      puts 'Preparing database...Done'
    end
  end
end

# rubocop:disable Metrics/MethodLength
def create_file_resources
  snapshot_id = FactoryGirl.create(:file_resource_snapshot).id
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
end
# rubocop:enable Metrics/MethodLength

def create_revision_with_all_file_resources_committed(parent: nil)
  revision = FactoryGirl.create(:revision, parent: parent)

  columns = %i[file_resource_id file_resource_snapshot_id revision_id]
  rows = FileResource.all.pluck(:id, :current_snapshot_id)
                     .map { |v| v.push(revision.id) }
  CommittedFile.import columns, rows, validate: false
end
