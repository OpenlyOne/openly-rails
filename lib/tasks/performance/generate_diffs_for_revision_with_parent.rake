# frozen_string_literal: true

desc 'Performance: Generate diffs for revision with parent'
namespace :performance do
  task generate_diffs_for_revision_with_parent:
       ['generate_diffs_for_revision_with_parent:all']

  namespace :generate_diffs_for_revision_with_parent do
    task all: %i[cleanup prepare test]
  end
end
