# frozen_string_literal: true

desc 'Performance: Generate diffs for revision with parent: Cleanup'
namespace :performance do
  namespace :generate_diffs_for_revision_with_parent do
    task cleanup: :test_environment do
      puts 'Cleanup: FileDiff'
      FileDiff.delete_all
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
