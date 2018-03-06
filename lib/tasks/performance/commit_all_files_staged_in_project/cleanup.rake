# frozen_string_literal: true

desc 'Performance: Commit all files staged in project: Cleanup'
namespace :performance do
  namespace :commit_all_files_staged_in_project do
    task cleanup: :test_environment do
      puts 'Cleanup: StagedFile'
      StagedFile.delete_all
      puts 'Cleanup: CommittedFile'
      CommittedFile.delete_all
      puts 'Cleanup: Reset current snapshot'
      FileResource.in_batches(of: 10_000).each_with_index do |relation, n|
        relation.update_all(current_snapshot_id: nil)
        puts "Progress: #{(n + 1)}x10000"
      end
      puts 'Cleanup: Snapshot'
      FileResource::Snapshot.delete_all
      puts 'Cleanup: FileResource'
      FileResource.in_batches(of: 10_000).each_with_index do |relation, n|
        relation.delete_all
        puts "Progress: #{(n + 1)}x10000"
      end
      puts 'Cleanup: Revision'
      Revision.delete_all
      puts 'Cleanup: Project'
      Project.delete_all

      puts 'Cleanup...Done'
    end
  end
end
