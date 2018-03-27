# frozen_string_literal: true

# Base class for all app mailers
class ApplicationMailer < ActionMailer::Base
  default from: 'hello@upshift.one'
  layout 'mailer'
end
