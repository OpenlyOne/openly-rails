# frozen_string_literal: true

require 'factory_girl'

desc 'Performance: Commit all files staged in project: Prepare'
namespace :performance do
  namespace :commit_all_files_staged_in_project do
    task prepare: :test_environment do
      puts 'Preparing database'

      snapshot_id = FactoryGirl.create(:file_resource_snapshot).id
      batch_size = 10_000
      columns = %i[provider_id external_id mime_type name content_version
                   current_snapshot_id]

      8.times do |n|
        rows = []
        batch_size.times do |batch_n|
          rows << [0, (batch_n + batch_size * n).to_s, 'doc', 'name', '1',
                   snapshot_id]
        end
        FileResource.import columns, rows, validate: false
        puts "Progress: #{(n + 1) * batch_size} records created"
      end

      puts 'Staging all file resources'

      project = FactoryGirl.create(:project)
      rows = FileResource.all.pluck(:id).map { |v| [v].push(project.id) }
      StagedFile.import %i[file_resource_id project_id], rows, validate: false

      puts 'Preparing database...Done'
    end
  end
end
