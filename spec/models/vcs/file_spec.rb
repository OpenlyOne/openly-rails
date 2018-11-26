# frozen_string_literal: true

require 'models/shared_examples/acting_as_hash_id'

RSpec.describe VCS::File, type: :model do
  subject(:file) { build_stubbed :vcs_file }

  it_should_behave_like 'acting as hash ID' do
    subject(:model)       { file }
    let(:minimum_length)  { 20 }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:repository).dependent(false) }
    it { is_expected.to have_many(:thumbnails).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:repository_branches)
        .through(:repository)
        .source(:branches)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:staged_instances).class_name('VCS::FileInBranch')
    end
    it { is_expected.to have_many(:versions).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:versions_of_children)
        .class_name('VCS::Version')
        .with_foreign_key(:parent_id)
        .dependent(:destroy)
    end
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
