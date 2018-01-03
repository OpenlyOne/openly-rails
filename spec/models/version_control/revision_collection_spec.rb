# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'

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
    subject(:method)  { revision_collection.last }
    it                { is_expected.to be nil }

    context 'when a previous revision exists' do
      before            { create :revision, repository: repository }
      let(:last_commit) { repository.rugged_repository.last_commit }

      it do
        is_expected.to be_an_instance_of VersionControl::Revisions::Committed
      end

      it 'has the id of the last revision' do
        expect(method).to have_attributes(id: last_commit.oid)
      end

      it_behaves_like 'caching method call', :last do
        subject { revision_collection }
      end
    end
  end

  describe '#reload' do
    subject(:method) { revision_collection.reload }

    it { is_expected.to eq revision_collection }

    it 'resets @last instance variable' do
      revision_collection.instance_variable_set(:@last, 'cached')
      expect { method }.to(
        change { revision_collection.instance_variable_get :@last }
          .from('cached').to(nil)
      )
    end
  end
end
