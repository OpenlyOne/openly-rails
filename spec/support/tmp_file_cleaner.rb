# frozen_string_literal: true

# Clean up (delete) spec/tmp directory after each spec
RSpec.configure do |config|
  config.after(:each) do
    FileUtils.rm_rf Rails.root.join('spec', 'tmp/.')
  end
end

# Clean up (delete) public/spec directory after each spec
RSpec.configure do |config|
  config.after(:each) do
    FileUtils.rm_rf Rails.root.join('public', 'spec/.')
  end
end
