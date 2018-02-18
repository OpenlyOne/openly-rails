# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_revision.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Revisions::Staged, type: :model do
  subject(:revision)  { repository.stage }
  let(:repository)    { build :repository }

  it_should_behave_like 'being a revision'

  describe 'delegations' do
    it 'delegates index to repository with prefix :repository' do
      expect_any_instance_of(Rugged::Repository).to receive :index
      subject.repository_index
    end
  end

  describe '#save' do
    subject(:method)  { revision.save }
    let!(:root)       { create :file, :root, repository: repository }
    let!(:folder)     { create :file, :folder, parent: root }
    let!(:file)       { create :file, parent: root }
    let!(:subfolder)  { create :file, :folder, parent: folder }
    let!(:subfile)    { create :file, parent: folder }
    let(:tree)        { repository.send(:lookup, method) }
    let(:subtree) do
      repository.send(
        :lookup,
        tree.entries.find { |entry| entry[:type] == :tree }[:oid]
      )
    end
    let(:subsubtree) do
      repository.send(
        :lookup,
        subtree.entries.find { |entry| entry[:type] == :tree }[:oid]
      )
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { revision }
    end

    it { is_expected.to be_a String }
    it "returns the created tree's object id" do
      expect(tree).to be_an_instance_of Rugged::Tree
    end

    it 'has last revision entry in top-level tree' do
      revision_entry =
        tree.entries.find { |entry| entry[:name] == '.last-revision' }
      expect(revision_entry).to be_present
    end

    it 'has root entry in top-level tree' do
      root_entry = tree.entries.find { |entry| entry[:name] == root.id }
      expect(root_entry).to be_present
    end

    it 'has three entries in 2nd-level tree' do
      expect(subtree.count).to eq 3
      expect(subtree.entries.map { |entry| entry[:name] })
        .to contain_exactly '.self', file.id, folder.id
    end

    it 'has three entries in 3rd-level tree' do
      expect(subsubtree.count).to eq 3
      expect(subsubtree.entries.map { |entry| entry[:name] })
        .to contain_exactly '.self', subfile.id, subfolder.id
    end

    context 'when no previous revision exists' do
      it 'writes nothing to .last-revision entry' do
        subject
        revision_entry =
          tree.entries.find { |entry| entry[:name] == '.last-revision' }
        revision_blob = repository.lookup(revision_entry[:oid])
        expect(revision_blob.text).to eq ''
      end
    end

    context 'when a previous revision exists' do
      before        { create :git_revision, repository: repository }
      let(:message) { '1st revision' }
      let(:author)  { { name: 'User', email: '1' } }

      it 'writes ID of last revision in .last-revision entry' do
        subject
        revision_entry =
          tree.entries.find { |entry| entry[:name] == '.last-revision' }
        revision_blob = repository.lookup(revision_entry[:oid])
        expect(revision_blob.text).to eq repository.revisions.last.id
      end
    end
  end
end
