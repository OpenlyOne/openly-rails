# frozen_string_literal: true

require 'models/shared_examples/version_control/using_repository_locking.rb'

RSpec.describe VersionControl::RevisionCollection, type: :model do
  subject(:revision_collection) { repository.revisions }
  let(:repository)              { build :repository }

  describe 'attributes' do
    it { should respond_to(:repository) }
  end

  describe 'delegations' do
    it 'delegates #lock to repository' do
      expect_any_instance_of(VersionControl::Repository).to receive :lock
      subject.lock
    end
  end

  describe '#last' do
    subject(:method) { revision_collection.last }

    it_should_behave_like 'using repository locking' do
      let(:locker) { revision_collection }
    end

    it { is_expected.to be nil }

    context 'when a previous revision exists' do
      before            { create :revision, repository: repository }
      let(:last_commit) { repository.rugged_repository.last_commit }

      it do
        is_expected.to be_an_instance_of VersionControl::Revisions::Committed
      end

      it 'has the id of the last revision' do
        expect(method).to have_attributes(id: last_commit.oid)
      end
    end
  end
end
