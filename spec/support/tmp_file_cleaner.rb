# frozen_string_literal: true

# Clean up (delete) spec/tmp directory after all specs have run
RSpec.configure do |config|
  config.after(:each) do
    FileUtils.rm_rf Rails.root.join('spec/tmp/.')
  end
end
