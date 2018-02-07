# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.2'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.21'
# Use Puma as the app server
gem 'puma', '3.8.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Autoprefix CSS rules using values from Can I Use
gem 'autoprefixer-rails', '~> 7.1'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# Use slim templating
gem 'slim', '~> 3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more:
# https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Material Design
gem 'materialize-sass', '~> 0.100'
# MaterializeCSS requires JQuery
gem 'jquery-rails', '~> 4.3'
# Use figaro for managing ENV variables
gem 'figaro', '~> 1.1'
# Use Devise for authentication
gem 'devise', '~> 4.3'
# Use CanCanCan for authorization (permission management)
gem 'cancancan', '~> 2.0'
# Nokogiri for parsing fields with errors
gem 'nokogiri', '~> 1.8.1'
# For simplified Rails configuration
gem 'config', '~> 1.4'
# Rugged for Git integration
gem 'rugged', '~> 0.26',
    git: 'https://github.com/libgit2/rugged.git', submodules: true
# Sequenced for scoped IDs
gem 'sequenced', '~> 3.1'
# Google API Client Library for interacting with the Google Drive API
gem 'google-api-client', '~> 0.17'
# Delayed job for processing background jobs, such as Google Drive requests
gem 'delayed_job_active_record', '~> 4.1'
# Daemons for daemonizing the DelayedJob workers
gem 'daemons', '~> 1.2'
# Filelock for extended file locking (simple timeout and wait)
gem 'filelock'
# Error-tracking with Rollbar
gem 'rollbar', '~> 2.15'
# Paperclip for attachments
gem 'paperclip', '~> 5.2'

group :development, :test do
  # We will use pry rails as our console
  gem 'pry-rails', '~> 0.3'
  # and also as our debugger
  gem 'pry-byebug', '~> 3.4'
  # Use Rspec for testing
  gem 'rspec-rails', '~> 3.5'
  # We will use bullet to avoid N+1 queries
  gem 'bullet', '~> 5.6'
  # Use FactoryGirl for generating factories
  gem 'factory_girl_rails', '~> 4.8'
  # Quickly generate fake names, urls, etc
  gem 'faker', '~> 1.8'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Access an IRB console on exception pages or by using <%= console %> anywhere
  # in the code.
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in
  # the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Automatically run tests when files update
  gem 'guard-rspec', '~> 4.7', require: false
  # Capistrano for deployment
  gem 'capistrano',               '~> 3.9', require: false
  gem 'capistrano-bundler',       '~> 1.2', require: false
  gem 'capistrano-figaro-yml',    '~> 1.0', require: false
  gem 'capistrano-rails',         '~> 1.3', require: false
  gem 'capistrano-rvm',           '~> 0.1', require: false
  gem 'capistrano3-puma',         '~> 3.1', require: false
  # Capistrano integration for the rails console
  gem 'capistrano-rails-console', '~> 2.2', require: false
  # Capistrano integration for DelayedJob
  gem 'capistrano3-delayed-job', '~> 1.7'
  # Generate favicons
  gem 'rails_real_favicon'
end

group :test do
  # Track code coverage with Codecov
  gem 'codecov', '~> 0.1', require: false
  # Behavior-Driven-Development
  gem 'capybara', '~> 2.14'
  # Additional RSpec matchers
  gem 'shoulda-matchers', '~> 3.1',
      git: 'https://github.com/thoughtbot/shoulda-matchers.git',
      branch: 'rails-5'
  # Cleans the test database after every test
  gem 'database_cleaner', '~> 1.6'
  # VCR for capturing HTTP requests during tests
  gem 'vcr', '~> 4.0'
  # Webmock for VCR to hook into
  gem 'webmock', '~> 3.3'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
