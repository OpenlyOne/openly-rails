# frozen_string_literal: true

# Create accounts from data passed in a CSV file
# CSV file must have columns :email, :password, :name, and :handle
# Pass path to CSV file when invoking task:
# rake accounts:create_from_csv['path']
desc 'Accounts: Create from CSV file'
namespace :accounts do
  task :create_from_csv, [:file_path] => :environment do |_task, args|
    require 'csv'

    CSV.foreach(args[:file_path], headers: true) do |row|
      values = row.to_hash.symbolize_keys
      puts "Creating account for #{values[:email]}..."
      a = Account.new(values.slice(:email, :password))
      a.build_user(values.slice(:name, :handle))
      a.save!
    end
  end
end
