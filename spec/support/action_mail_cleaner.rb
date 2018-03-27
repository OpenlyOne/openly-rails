# frozen_string_literal: true

# Clear action mailer deliveries
RSpec.configure do |config|
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
end
