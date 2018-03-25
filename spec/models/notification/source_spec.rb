# frozen_string_literal: true

RSpec.describe Notification::Source, type: :model do
  describe '.for_revision(revision)' do
    subject(:recipients)  { described_class.for_revision(revision) }
    let(:revision)        { instance_double Revision }

    before { allow(revision).to receive(:author).and_return 'author' }

    it { is_expected.to eq 'author' }
  end
end
