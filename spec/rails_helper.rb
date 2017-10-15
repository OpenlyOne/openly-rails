# frozen_string_literal: true

# Start coverage analysis
if ENV['CI'] == 'true' || ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start 'rails'
end

# Report coverage to codecov during CI
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('Rails is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'shoulda/matchers'
require 'faker'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
require Rails.root.join('spec', 'support', 'database_cleaner.rb')
require Rails.root.join('spec', 'support', 'tmp_file_cleaner.rb')
require Rails.root.join('spec', 'support', 'helpers', 'features_helper.rb')

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # Randomize order in which tests are run
  config.order = 'random'

  # enable Bullet for avoiding N+1 queries, unused eager loading, and lack of
  # counter cache
  if Bullet.enable?
    config.before(type: :feature) do
      Bullet.start_request
    end

    config.after(type: :feature) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  # Enable partial rendering from application folder
  # Fixes https://github.com/rspec/rspec-rails/issues/396
  # Solution: https://github.com/verypossible/raygun-rails-template/pull/14
  config.before(:example, type: :view) do
    view.lookup_context.view_paths.unshift 'app/views/application'
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Include Devise test helpers
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Include Feature test helpers
  config.include FeaturesHelper, type: :feature

  # add this line at the bottom of the config section
  # it saves us time when using FactoryGirl methods.
  config.include FactoryGirl::Syntax::Methods
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
