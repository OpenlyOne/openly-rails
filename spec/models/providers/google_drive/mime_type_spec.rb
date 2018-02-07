# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::MimeType, type: :model do
  subject(:type) { Providers::GoogleDrive::MimeType }

  it { expect(type.document).to eq 'application/vnd.google-apps.document' }
  it { expect(type.folder).to   eq 'application/vnd.google-apps.folder' }
  it do
    expect(type.spreadsheet).to eq 'application/vnd.google-apps.spreadsheet'
  end
end
