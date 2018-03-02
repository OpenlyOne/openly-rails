# frozen_string_literal: true

desc 'Performance: Generate diffs for revision with parent: Test'
namespace :performance do
  namespace :generate_diffs_for_revision_with_parent do
    task test: :test_environment do
      revision = Revision.last

      puts "Benchmarking with #{revision.committed_files.count} records"

      time = Benchmark.realtime { revision.generate_diffs }

      puts "Completed in #{time} seconds"
    end
  end
end
