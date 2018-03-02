# frozen_string_literal: true

desc 'Performance: Generate diffs for origin revision'
namespace :performance do
  task generate_diffs_for_origin_revision:
       ['generate_diffs_for_origin_revision:all']

  namespace :generate_diffs_for_origin_revision do
    task all: %i[cleanup prepare test]
  end
end
