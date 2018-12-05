# frozen_string_literal: true

RSpec.describe VCS::File, type: :model do
  describe '.hashid_to_id(hashid)' do
    subject { described_class.hashid_to_id(hashid) }

    let(:hashid)  { VCS::File.hashids.encode(id) }
    let(:id)      { 27 }

    it { is_expected.to eq id }

    context 'when hashid is an integer' do
      let(:hashid) { 42 }

      it { is_expected.to be nil }
    end

    context 'when hashid is a stringified integer' do
      let(:hashid) { '42' }

      it { is_expected.to be nil }
    end

    context 'when hashid contains odd characters' do
      let(:hashid) { '-----' }

      it { is_expected.to be nil }
    end
  end
end
