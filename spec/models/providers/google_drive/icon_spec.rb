# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::Icon, type: :model do
  subject(:icon) { Providers::GoogleDrive::Icon }

  describe '.for(mime_type:)' do
    subject { icon.for(mime_type: 'type') }

    before do
      allow(Providers::GoogleDrive::MimeType)
        .to receive(:to_symbol).with('type').and_return symoblic_type
    end

    context 'when symbolic type is supported' do
      let(:symoblic_type) { :document }

      it { is_expected.to eq 'files/document.png' }
    end

    context 'when symbolic type is unsupported' do
      let(:symoblic_type) { :unsupported }

      before do
        allow(icon).to receive(:default).with('type').and_return 'default.png'
      end

      it { is_expected.to eq 'default.png' }
    end
  end

  describe '.default(mime_type)' do
    subject { icon.default('MIME-TYPE') }

    it do
      is_expected.to eq(
        'https://drive-thirdparty.googleusercontent.com/128/type/MIME-TYPE'
      )
    end
  end
end
