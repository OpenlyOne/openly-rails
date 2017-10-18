# frozen_string_literal: true

RSpec.describe VersionControl::Contribution, type: :model do
  subject(:contribution) { build :vc_contribution }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe 'delegations' do
    it 'delegates #oid' do
      expect_any_instance_of(Rugged::Commit).to receive :oid
      subject.oid
    end
    it 'delegates #oid' do
      expect_any_instance_of(Rugged::Commit).to receive :oid
      subject.oid
    end
  end

  describe '.new(rugged_commit)' do
    context 'when rugged_commit is nil' do
      subject(:contribution) { build :vc_contribution, file: nil }

      it 'raises an error' do
        expect { subject }.to raise_error(
          'VersionControl::Contribution must initialized with a ' \
          'Rugged::Commit instance'
        )
      end
    end
  end

  describe '#created_at' do
    subject(:method) { contribution.created_at }
    let(:contribution) { build :vc_contribution, file: file }
    let(:file) { create :vc_file }
    let!(:commit_timestamp) { file.send(:last_commit).time }

    it { is_expected.to eq commit_timestamp }
    it 'should return time in UTC' do
      expect(method.zone).to eq 'UTC'
    end
  end

  describe '#author' do
    subject(:method) { contribution.author }
    let(:contribution) { build :vc_contribution, file: file }
    let(:file) { create :vc_file, revision_author: commit_author }
    let(:commit_author) { create(:user) }

    it { is_expected.to eq commit_author }
  end
end
