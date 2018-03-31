# frozen_string_literal: true

RSpec.describe Provider, type: :model do
  describe '.find(id)' do
    it { expect(Provider.find(0)).to eq Providers::GoogleDrive }
  end
end
