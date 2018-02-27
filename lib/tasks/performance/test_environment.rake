# frozen_string_literal: true

desc 'Abort unless Rails is in test environment'
task test_environment: :environment do
  abort('Task should be run in test environment!') unless Rails.env.test?
end
