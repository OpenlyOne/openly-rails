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
    it { is_expected.to delegate_method(:rugged_repository).to(:repository) }
  end

  describe '#all', isolated_unit_test: true do
    subject(:method)    { collection.all }
    let(:collection)    { VersionControl::RevisionCollection.new(nil) }
    let(:rugged_repo)   { instance_double Rugged::Repository }
    let(:commits)       { %w[commit3 commit2 commit1] }
    let(:revisions)     { %w[revision3 revision2 revision1] }

    before do
      expect(collection).to receive(:rugged_repository).and_return rugged_repo
      expect(collection).to receive(:_last_rugged_commit).and_return commits[0]

      expect(Rugged::Walker).to receive(:walk)
        .with(rugged_repo, show: commits[0], simplify: true)
        .and_return commits

      expect(VersionControl::Revisions::Committed)
        .to receive(:new).with(collection, commits[0]).and_return revisions[0]
      expect(VersionControl::Revisions::Committed)
        .to receive(:new).with(collection, commits[1]).and_return revisions[1]
      expect(VersionControl::Revisions::Committed)
        .to receive(:new).with(collection, commits[2]).and_return revisions[2]
    end

    it { is_expected.to eq revisions }

    it_behaves_like 'caching method call', :all do
      subject { collection }
    end
  end

  describe '#all_as_diffs', isolated_unit_test: true do
    subject(:method)  { collection.all_as_diffs }
    let(:collection)  { VersionControl::RevisionCollection.new(nil) }
    let(:revisions)   { [revision1, revision2, revision3] }
    let(:revision1)   { instance_double VersionControl::Revisions::Committed }
    let(:revision2)   { instance_double VersionControl::Revisions::Committed }
    let(:revision3)   { instance_double VersionControl::Revisions::Committed }
    let(:diffs)       { %w[diff1 diff2 diff3] }

    before do
      expect(collection).to receive(:all).and_return revisions
      expect(revision1).to receive(:diff).with(revision2).and_return diffs[0]
      expect(revision2).to receive(:diff).with(revision3).and_return diffs[1]
      expect(revision3).to receive(:diff).with(nil).and_return diffs[2]
    end

    it { is_expected.to eq diffs }
  end

  describe '#last' do
    subject(:method)  { revision_collection.last }
    it                { is_expected.to be nil }

    context 'when a previous revision exists' do
      before            { create :git_revision, repository: repository }
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

  describe '#_last_rugged_commit', isolated_unit_test: true do
    subject(:method)    { collection.send :_last_rugged_commit }
    let(:collection)    { VersionControl::RevisionCollection.new(nil) }
    let(:rugged_repo)   { instance_double Rugged::Repository }
    let(:branches)      { instance_double Rugged::BranchCollection }
    let(:master_branch) { instance_double Rugged::Branch }
    let(:last_commit)   { instance_double Rugged::Commit }

    before do
      expect(collection).to receive(:rugged_repository).and_return rugged_repo
      expect(rugged_repo).to receive(:branches).and_return branches
      allow(branches).to receive(:[]).with('master').and_return master_branch
      allow(master_branch).to receive(:target).and_return last_commit
    end

    it { is_expected.to eq last_commit }

    context 'when master branch does not exist' do
      before { allow(branches).to receive(:[]).and_return nil }

      it { is_expected.to be nil }
    end
  end
end
