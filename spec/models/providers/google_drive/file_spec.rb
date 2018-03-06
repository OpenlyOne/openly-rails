# frozen_string_literal: true

RSpec.describe Providers::GoogleDrive::File, type: :model do
  subject(:file) { Providers::GoogleDrive::File.new }

  describe '.deleted?(file)' do
    subject(:deleted) { described_class.deleted?(file) }
    it                { is_expected.to eq false }

    context 'when file is nil (deleted)' do
      let(:file)  { nil }
      it          { is_expected.to eq true }
    end

    context 'when file is trashed' do
      before  { file.trashed = true }
      it      { is_expected.to eq true }
    end
  end
end
