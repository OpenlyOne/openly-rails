# frozen_string_literal: true

# Patch action mailer delivery job to handle references
# Wrap in Rails.configuration.to_prepare according to
# https://stackoverflow.com/a/7670266/6451879
Rails.configuration.to_prepare do
  ActionMailer::DeliveryJob.include Referenceable
end
