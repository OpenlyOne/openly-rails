# frozen_string_literal: true

RSpec.shared_examples 'acting as hash ID' do
  it '#to_param returns a hash id' do
    expect(subject.to_param).to be_an_instance_of String
    expect(subject.to_param).not_to eq subject.id
  end

  it 'responds to .hashids' do
    expect(described_class.hashids).to be_an_instance_of Hashids
  end

  it 'has the correct minimum length' do
    expect(subject.to_param.length).to be >= minimum_length
  end

  describe '.hashid_to_id(hashid)' do
    subject(:decoded_hashid)  { described_class.hashid_to_id(hashid) }

    let(:hashids)             { instance_double Hashids }
    let(:hashid)              { instance_double Integer }
    let(:stringified_hashid)  { instance_double String }
    let(:decode_output)       { %w[r1 r2 r3] }

    before do
      allow(described_class).to receive(:hashids).and_return hashids
      allow(hashids).to receive(:decode).and_return decode_output
      allow(hashid).to receive(:to_s).and_return stringified_hashid
    end

    it 'calls #decode on stringified hashid and returns the first result' do
      expect(decoded_hashid).to eq 'r1'
      expect(hashids).to have_received(:decode).with(stringified_hashid)
    end

    context 'when #decode returns nil' do
      let(:decode_output) { nil }

      it { is_expected.to be nil }
    end

    context 'when #decode returns empty array' do
      let(:decode_output) { [] }

      it { is_expected.to be nil }
    end

    context 'when Hashids::InputError is encountered' do
      before do
        allow(hashids).to receive(:decode).and_raise Hashids::InputError
      end

      it { is_expected.to be nil }
    end
  end

  describe '.id_to_hashid(id)' do
    subject(:encoded_id) { described_class.id_to_hashid(id) }

    let(:hashids) { instance_double Hashids }
    let(:id)      { instance_double Integer }

    before do
      allow(described_class).to receive(:hashids).and_return hashids
      allow(hashids).to receive(:encode).and_return 'en(*d3d'
    end

    it 'calls #decode on stringified hashid and returns the first result' do
      expect(encoded_id).to eq 'en(*d3d'
      expect(hashids).to have_received(:encode).with(id)
    end
  end
end
