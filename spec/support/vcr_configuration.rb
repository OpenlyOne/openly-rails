# frozen_string_literal: true

# Configure VCR
VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

  # Uncomment to re-record any cassettes older than 7 days
  # c.default_cassette_options = { re_record_interval: 7.days }

  # List of Google accounts used in specs
  google_accounts = {
    'TRACKING ACCOUNT': ENV['GOOGLE_DRIVE_TRACKING_ACCOUNT'],
    'USER ACCOUNT':     ENV['GOOGLE_DRIVE_USER_ACCOUNT']
  }

  # transform email values to drive services
  google_accounts.transform_values! do |email|
    Providers::GoogleDrive::DriveService.new(email)
  end

  # Filter access & refresh tokens for each google account
  google_accounts.each do |account, service|
    # Filter email address
    c.filter_sensitive_data("<EMAIL ADDRESS FOR #{account}>") do
      service.google_account
    end

    c.filter_sensitive_data("<ACCESS TOKEN FOR #{account}>") do
      service.reload.authorization.access_token
    end

    c.filter_sensitive_data("<REFRESH TOKEN FOR #{account}>") do
      CGI.escape(service.reload.authorization.refresh_token)
    end
  end

  # Filter client ID & secret
  c.filter_sensitive_data('<CLIENT ID>') { ENV['GOOGLE_DRIVE_CLIENT_ID'] }
  c.filter_sensitive_data('<CLIENT SECRET>') do
    ENV['GOOGLE_DRIVE_CLIENT_SECRET']
  end

  # Filter user agent
  c.filter_sensitive_data('<USER AGENT>') do
    google_accounts.values.first.send(:user_agent)
  end

  # Raise error if OAuth2 request contains unfiltered sensitive data
  c.before_record do |interaction|
    next unless interaction.request.uri.include? 'oauth2/v4/token'

    # check request
    oauth_request_params = CGI.parse(interaction.request.body)
    oauth_request_params.except('grant_type').each do |param, param_value|
      param_value.each do |value|
        # everything is good if the value starts with < and ends with >
        next if value.match?(/^<.*>$/)

        # error: Value has not been filtered
        raise 'OAuth2 request includes unfiltered parameters: ' \
              "#{param}=#{param_value}"
      end
    end

    # check response
    oauth_response_params = JSON.parse(interaction.response.body)
    oauth_response_params
      .except('token_type', 'expires_in', 'scope').each do |param, value|
      # everything is good if the value starts with < and ends with >
      next if value.match?(/^<.*>$/)

      # error: Value has not been filtered
      raise 'OAuth2 response includes unfiltered parameters: ' \
            "#{param}=#{value}"
    end
  end

  # Raise error if request contains unfiltered Bearer token in headers
  c.before_record do |interaction|
    authorization_header = interaction.request.headers['Authorization']
    next unless authorization_header.present?

    next if authorization_header.join('').match?(/^Bearer <.*>$/)

    # error token was not filtered
    raise("Request: #{interaction.request.uri} " \
          'includes unfiltered Bearer access token')
  end
end
