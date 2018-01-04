# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/for_file_diff.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::FileDiff, type: :model do
  subject(:diff) do
    VersionControl::FileDiff.new(revision_diff, base, differentiator)
  end
  let(:revision_diff)   { VersionControl::RevisionDiff.new(nil, nil) }
  let(:base)            { build :file }
  let(:differentiator)  { build :file, parent_id: base&.parent_id }

  describe 'attributes' do
    it { should respond_to(:revision_diff) }
    it { should respond_to(:base) }
    it { should respond_to(:differentiator) }
  end

  describe 'delegations' do
    before { subject }

    it 'delegates base to revision_diff with prefix: revision' do
      expect(revision_diff).to receive(:base)
      subject.send :revision_base
    end

    it 'delegates differentiator to revision_diff with prefix: revision' do
      expect(revision_diff).to receive(:differentiator)
      subject.send :revision_differentiator
    end
  end

  describe '#ancestors_of_file' do
    include_context 'file diff with files'

    subject(:method)        { diff.ancestors_of_file }

    let(:root)              { create :file, :root,    repository: repository }
    let(:parent_of_parent)  { create :file, :folder,  parent: root }
    let(:parent)            { create :file, :folder,  parent: parent_of_parent }
    let(:file)              { create :file,           parent: parent }
    let(:create_files)      { file }

    it { is_expected.to eq diff.base.ancestors }
    it 'has ancestors: parent, parent_of_parent, root' do
      expect(method.map(&:id)).to eq [parent, parent_of_parent, root].map(&:id)
    end

    it_behaves_like 'caching method call', :ancestors_of_file do
      subject { diff }
    end

    context 'when base is nil' do
      include_context 'base is nil'

      it 'has ancestors: parent, parent_of_parent, root' do
        expect(method.map(&:id))
          .to eq [parent, parent_of_parent, root].map(&:id)
      end

      context 'when ancestor has been updated in revision base' do
        # move parent to root folder, changing the ancestry path from
        # 'root > parent of parent > parent' to 'root > parent'
        before { parent.update name: 'Updated Folder', parent_id: root.id }

        it 'has ancestors: parent_of_parent, root' do
          expect(method.map(&:id)).to eq [parent, root].map(&:id)
        end

        it 'returns files with current/up-to-date names' do
          expect(method.map(&:name)).to eq ['Updated Folder', root.name]
        end
      end

      it_behaves_like 'locking repository only when revision base is stage'
    end
  end

  describe '#been_added?' do
    subject(:method)  { diff.been_added? }
    it                { is_expected.to be false }

    it_behaves_like 'when base is nil, returns:', false
    it_behaves_like 'when differentiator is nil, returns:', true
  end

  describe '#been_changed?' do
    subject(:method)  { diff.been_changed? }
    it                { is_expected.to be false }

    context 'when base has been added' do
      before  { allow(diff).to receive(:been_added?) { true } }
      it      { is_expected.to be true }
    end

    context 'when base has been modified' do
      before  { allow(diff).to receive(:been_modified?) { true } }
      it      { is_expected.to be true }
    end

    context 'when base has been moved' do
      before  { allow(diff).to receive(:been_moved?) { true } }
      it      { is_expected.to be true }
    end

    context 'when base has been deleted' do
      before  { allow(diff).to receive(:been_deleted?) { true } }
      it      { is_expected.to be true }
    end

    it_behaves_like 'when base is nil, returns:', true
    it_behaves_like 'when differentiator is nil, returns:', true
  end

  describe '#been_modified?' do
    subject { diff.been_modified? }
    it      { is_expected.to be false }

    context "when base's modified time > differentiator's modified time" do
      before do
        base.instance_variable_set :@modified_time, Time.zone.now.tomorrow
      end
      it { is_expected.to be true }
    end

    it_behaves_like 'when base is nil, returns:', false
    it_behaves_like 'when differentiator is nil, returns:', false
  end

  describe '#been_moved?' do
    subject { diff.been_moved? }
    it      { is_expected.to be false }

    context 'when base and differentiator have a different parent_id' do
      let(:differentiator)  { build :file, parent_id: "#{base.parent_id}123" }
      it                    { is_expected.to be true }
    end

    it_behaves_like 'when base is nil, returns:', false
    it_behaves_like 'when differentiator is nil, returns:', false
  end

  describe '#been_deleted?' do
    subject(:method)  { diff.been_deleted? }
    it                { is_expected.to be false }
    it_behaves_like 'when base is nil, returns:', true
    it_behaves_like 'when differentiator is nil, returns:', false
  end

  describe '#children_as_diffs' do
    include_context 'file diff with children'

    subject(:method) { diff.children_as_diffs }

    it { expect(method.count).to eq 9 }

    it 'contains diff for the three files that have remained' do
      expect(method.reject(&:been_changed?).map(&:id_is_or_was))
        .to contain_exactly 'remain1', 'remain2', 'remain3'
    end

    it 'contains diff for the two files that have been added' do
      expect(method.select(&:been_added?).map(&:id_is_or_was))
        .to contain_exactly 'add1', 'add2'
    end

    it 'contains diff for the two files that have been moved in' do
      expect(method.select(&:been_moved?).map(&:id_is_or_was))
        .to contain_exactly 'move_in1', 'move_in2'
    end

    it 'contains diff for the two files that have been deleted' do
      expect(method.select(&:been_deleted?).map(&:id_is_or_was))
        .to contain_exactly 'delete1', 'delete2'
    end

    it 'does not contain diff for the two files that have been moved out' do
      expect(method).not_to(be_any { |diff| diff.id_is_or_was == 'move_out1' })
      expect(method).not_to(be_any { |diff| diff.id_is_or_was == 'move_out2' })
    end

    it_behaves_like 'caching method call', :children_as_diffs do
      subject { diff }
    end

    it_behaves_like 'expected when base has no children or is nil' do
      let(:mark_as) { :deleted }
      let(:file_ids) { %w[remain1 remain2 remain3 delete1 delete2] }
    end

    it_behaves_like 'expected when differentiator has no children or is nil' do
      let(:mark_as) { :added }
      let(:file_ids) { %w[remain1 remain2 remain3 add1 add2 move_in1 move_in2] }
    end

    it_behaves_like 'locking repository only when revision base is stage'
  end

  it_should_behave_like 'having is_or_was attribute', :file do
    let(:base_attribute)            { base }
    let(:differentiator_attribute)  { differentiator }
  end
  it_should_behave_like 'having is_or_was attribute', :id
  it_should_behave_like 'having is_or_was attribute', :directory? do
    let(:base)            { build :file, :folder }
    let(:differentiator)  { build :file }
    let(:method_name)     { 'is_or_was_directory?' }
  end
  it_should_behave_like 'having is_or_was attribute', :mime_type
  it_should_behave_like 'having is_or_was attribute', :name

  describe '#diffs_of_children_that_have_been_added' do
    include_context 'file diff with children'

    subject(:method) { diff.send :diffs_of_children_that_have_been_added }

    it 'returns diffs for added files and moved-in files' do
      expect(method.map(&:id_is_or_was))
        .to contain_exactly 'add1', 'add2', 'move_in1', 'move_in2'
    end

    it 'marks two returned diffs as added' do
      expect(method.select(&:been_added?).count).to eq 2
    end

    it 'marks two returned diffs as moved' do
      expect(method.select(&:been_moved?).count).to eq 2
    end

    it_behaves_like 'caching method call', :diffs_of_added_children do
      subject { diff }
      let(:method_name) { :diffs_of_children_that_have_been_added }
    end

    it_behaves_like 'expected when base has no children or is nil' do
      let(:mark_as) { :added }
      let(:file_ids) { [] }
    end

    it_behaves_like 'expected when differentiator has no children or is nil' do
      let(:mark_as) { :changed }
      let(:file_ids) { %w[remain1 remain2 remain3 add1 add2 move_in1 move_in2] }
    end
  end

  describe '#diffs_of_children_that_have_remained' do
    include_context 'file diff with children'

    subject(:method) { diff.send :diffs_of_children_that_have_remained }

    it 'returns diffs for remaining files' do
      expect(method.map(&:id_is_or_was))
        .to contain_exactly 'remain1', 'remain2', 'remain3'
    end

    it 'does not mark returned diffs as changed' do
      expect(method).to be_none(&:been_changed?)
    end

    it_behaves_like 'caching method call', :diffs_of_remained_children do
      subject { diff }
      let(:method_name) { :diffs_of_children_that_have_remained }
    end

    it_behaves_like 'expected when base has no children or is nil' do
      let(:mark_as) { :changed }
      let(:file_ids) { [] }
    end

    it_behaves_like 'expected when differentiator has no children or is nil' do
      let(:mark_as) { :changed }
      let(:file_ids) { [] }
    end
  end

  describe '#diffs_of_children_that_have_been_deleted' do
    include_context 'file diff with children'

    subject(:method) { diff.send :diffs_of_children_that_have_been_deleted }

    it 'returns diffs for deleted files' do
      expect(method.map(&:id_is_or_was)).to contain_exactly 'delete1', 'delete2'
    end

    it 'marks returned diffs as deleted' do
      expect(method).to be_all(&:been_deleted?)
    end

    it_behaves_like 'caching method call', :diffs_of_deleted_children do
      subject { diff }
      let(:method_name) { :diffs_of_children_that_have_been_deleted }
    end

    it_behaves_like 'expected when base has no children or is nil' do
      let(:mark_as) { :deleted }
      let(:file_ids) { %w[remain1 remain2 remain3 delete1 delete2] }
    end

    it_behaves_like 'expected when differentiator has no children or is nil' do
      let(:mark_as) { :deleted }
      let(:file_ids) { [] }
    end

    it_behaves_like 'locking repository only when revision base is stage'
  end
end
