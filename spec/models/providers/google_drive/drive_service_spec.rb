# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::DriveService, type: :model do
  subject(:type) { Providers::GoogleDrive::DriveService }

  describe '#initialize(google_account)' do
    subject(:service)     { described_class.new(google_account) }
    let(:google_account)  { 'example@gmail.com' }

    before do
      authorizer = instance_double Google::Auth::UserAuthorizer
      allow(described_class).to receive(:authorizer).and_return authorizer
      allow(authorizer)
        .to receive(:get_credentials)
        .with(google_account)
        .and_return 'auth'
    end

    it { is_expected.to be_a Google::Apis::DriveV3::DriveService }

    it 'sets application name' do
      expect(service.client_options.application_name).to eq 'Upshift One'
    end

    it 'sets authorization access token' do
      expect(service.request_options.authorization).to be_present
    end
  end
end
