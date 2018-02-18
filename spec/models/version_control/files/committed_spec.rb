# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_file.rb'
require 'models/shared_examples/caching_method_call.rb'

RSpec.describe VersionControl::Files::Staged, type: :model do
  subject(:file)          { build :committed_file }
  let(:root)              { create :file, :root, repository: repository }
  let(:repository)        { build :repository }
  let(:create_revision)   { create :git_revision, repository: repository }

  it_should_behave_like 'being a file'

  describe '#ancestors' do
    subject(:method) { file.ancestors }
    let(:file) do
      file = create :file, parent: parent
      create_revision
      repository.revisions.last.files.find_by_id(file.id)
    end
    let(:parent)            { create :file, :folder, parent: parent_of_parent }
    let(:parent_of_parent)  { create :file, :folder, parent: root }

    it 'returns [parent, parent_of_parent, root]' do
      expect(method.map(&:id)).to eq [parent.id, parent_of_parent.id, root.id]
    end

    it 'returns an array of committed files' do
      method.each do |ancestor|
        expect(ancestor).to be_a VersionControl::Files::Committed
      end
    end

    it_behaves_like 'caching method call', :ancestors do
      subject { file }
    end

    context 'when ancestor is just one' do
      let(:parent)  { root }
      it            { is_expected.to be_an Array }
      it            { expect(method[0].id).to eq root.id }
    end

    context 'when ancestors of file do not exist' do
      before  { file.instance_variable_set :@path, 'bla/bla/bla' }
      it      { is_expected.to eq [nil, nil] }
    end
  end

  describe '#children' do
    subject(:method) { file.children }
    let(:file) do
      file = create :file, :folder, parent: root
      create_revision
      repository.revisions.last.files.find_by_id(file.id)
    end

    it { is_expected.to be_an Array }
    it { is_expected.to be_empty }

    context 'when file is not a directory' do
      let!(:non_directory) { create :file, parent: root }
      let(:file) do
        create_revision
        repository.revisions.last.files.find_by_id(non_directory.id)
      end

      it { is_expected.to be nil }
    end

    context 'when file has children' do
      let(:parent)  { create :file, :folder, parent: root }
      let!(:files)  { create_list :file, 3, parent: parent }
      let(:file) do
        create_revision
        repository.revisions.last.files.find_by_id(parent.id)
      end

      it { expect(method.map(&:id)).to match_array(files.map(&:id)) }

      it_behaves_like 'caching method call', :children do
        subject { file }
      end
    end
  end
end
