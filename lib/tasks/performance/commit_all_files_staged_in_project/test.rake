# frozen_string_literal: true

desc 'Performance: Commit all files staged in project: Test'
namespace :performance do
  namespace :commit_all_files_staged_in_project do
    task test: :test_environment do
      project = Project.last

      puts "Benchmarking with #{project.staged_files.count} records"

      revision = Revision.create(project: project, parent: nil,
                                 author: project.owner)
      time = Benchmark.realtime { revision.commit_all_files_staged_in_project }

      puts "Completed in #{time} seconds"
    end
  end
end
