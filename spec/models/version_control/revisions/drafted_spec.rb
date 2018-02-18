# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/being_a_revision.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Revisions::Drafted, type: :model do
  subject(:revision)  { repository.build_revision }
  let(:repository)    { build :repository }

  it_should_behave_like 'being a revision' do
    before { subject }
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:title) }
    it { is_expected.to respond_to(:summary) }
    it { is_expected.to respond_to(:tree_id) }
  end

  describe 'validations' do
    let(:title) { 'Initial Revision' }
    before do
      revision.instance_variable_set :@title, title
    end

    it { is_expected.to be_valid }

    context 'when title is nil' do
      let(:title) { nil }
      it            { is_expected.to be_invalid }
    end

    context 'when title is blank' do
      let(:title) { '' }
      it            { is_expected.to be_invalid }
    end

    context 'when last_revision_id is not id of actual last revision' do
      before  { revision.instance_variable_set :@last_revision_id, 'abc' }
      before  { revision.valid? }

      it 'does not add a :base error' do
        expect(revision.errors[:last_revision_id])
          .to include('must match id of actual last revision')
      end
    end
  end

  describe '#commit' do
    subject(:method)  { revision.commit(title, summary, author) }
    let!(:root)       { create :file, :root, repository: repository }
    let!(:files)      { create_list :file, 5, parent: root }
    let(:title)       { 'Commit with Rugged' }
    let(:summary)     { '' }
    let(:author)      { { name: 'username', email: '1' } }

    it_should_behave_like 'using repository locking' do
      let(:locker) { revision }
    end

    it { is_expected.to be_truthy }

    it 'creates a commit in the repository' do
      method
      expect(repository.rugged_repository.last_commit).to be_present
    end

    it 'writes title and author to the commit' do
      method
      expect(repository.rugged_repository.last_commit).to have_attributes(
        message: title,
        author: hash_including(name: author[:name], email: author[:email])
      )
    end

    it 'saves the tree' do
      method
      expect(repository.rugged_repository.last_commit.tree).to eq revision.tree
    end

    context 'when optional summary is provided' do
      let(:summary) { 'This commit was made using Rugged/Libgit2' }
      it 'writes title and summary to the commit' do
        method
        expect(repository.rugged_repository.last_commit).to have_attributes(
          message: "Commit with Rugged\r\n\r\nThis commit was made using " \
                   'Rugged/Libgit2'
        )
      end
    end

    context 'when draft is invalid' do
      before { allow(revision).to receive(:valid?).and_return false }

      it { is_expected.to be false }

      it 'does not commit to the repository' do
        method
        expect(repository.rugged_repository).to be_empty
      end
    end

    context 'when previous commits have occurred' do
      before { create :git_revision, repository: repository }

      it 'changes last_commit' do
        expect { method }
          .to(change { repository.rugged_repository.last_commit })
      end
    end

    context 'when commit occurs after revision is built' do
      before { revision }
      before { allow(revision).to receive(:valid?).and_return true }
      before { create :git_revision, repository: repository }

      it 'raises Rugged::ObjectError' do
        expect { method }.to raise_error(
          Rugged::ObjectError,
          'failed to create commit: current tip is not the first parent'
        )
      end
    end
  end

  describe '#files', isolated_unit_test: true do
    subject(:method) { revision.files }
    let(:file_collection) do
      instance_double VersionControl::FileCollections::Committed
    end

    before do
      expect(VersionControl::FileCollections::Committed)
        .to receive(:new).with(revision).and_return file_collection
    end

    it 'returns the file collection' do
      is_expected.to eq file_collection
    end

    it_behaves_like 'caching method call', :files do
      subject { revision }
    end
  end

  describe '#tree' do
    subject(:method)  { revision.tree }
    let(:tree_id)     { revision.instance_variable_get :@tree_id }

    let!(:root)       { create :file, :root, repository: repository }
    let!(:files)      { create_list :file, 5, parent: root }

    it { is_expected.to be_an_instance_of Rugged::Tree }
    it { is_expected.to eq repository.send(:lookup, tree_id) }

    it_behaves_like 'caching method call', :tree do
      subject { revision }
    end

    context 'when tree_id is nil' do
      before  { revision.instance_variable_set :@tree_id, nil }
      it      { is_expected.to be nil }
    end
  end

  describe '#last_revision_id' do
    subject(:method)        { revision.send :last_revision_id }
    let(:last_revision_oid) { 'the-object-id-of-last-revision' }
    before do
      builder = Rugged::Tree::Builder.new(repository.rugged_repository)
      blob_id = repository.rugged_repository.write(last_revision_oid, :blob)
      builder << {
        type: :blob,
        name: '.last-revision',
        oid: blob_id,
        filemode: 0o0100644
      }
      revision.instance_variable_set :@tree_id, builder.write
    end

    it { is_expected.to eq last_revision_oid }

    it_behaves_like 'caching method call', :last_revision_id do
      subject { revision }
    end

    context 'when .last-revision file is empty' do
      let(:last_revision_oid) { '' }
      it                      { is_expected.to be nil }
    end
  end
end
