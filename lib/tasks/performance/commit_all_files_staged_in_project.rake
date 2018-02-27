# frozen_string_literal: true

desc 'Performance: Commit all files staged in project'
namespace :performance do
  task commit_all_files_staged_in_project:
       ['commit_all_files_staged_in_project:all']

  namespace :commit_all_files_staged_in_project do
    task all: %i[cleanup prepare test]
  end
end
