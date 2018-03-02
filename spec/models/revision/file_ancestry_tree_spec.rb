# frozen_string_literal: true

RSpec.describe Revision::FileAncestryTree, type: :model do
  subject(:ancestry_tree) do
    Revision::FileAncestryTree.new(revision: revision, file_ids: file_ids)
  end
  let(:revision)  { instance_double Revision }
  let(:file_ids)  { [1, 2, 3] }

  describe '.generate(revision:, file_ids:, depth:)' do
    subject(:generate)  { described_class.generate attributes }
    let(:attributes)    { { revision: 'r', file_ids: 'ids', depth: 'd' } }
    let(:new_tree)      { instance_double described_class }

    before do
      allow(described_class)
        .to receive(:new)
        .with(revision: 'r', file_ids: 'ids')
        .and_return new_tree
      allow(new_tree).to receive(:recursively_load_parents).with(depth: 'd')
    end

    it { is_expected.to eq new_tree }

    it 'recursively_load_parents depth-times' do
      expect(new_tree).to receive(:recursively_load_parents).with(depth: 'd')
      generate
    end
  end

  describe '#ancestors_names_for(file_id, depth:)' do
    subject(:ancestors_names) do
      ancestry_tree.send :ancestors_names_for, 1, depth: 3
    end

    let(:file)    { { name: 'file',     parent: 2 } }
    let(:parent1) { { name: 'parent1',  parent: 3 } }
    let(:parent2) { { name: 'parent2',  parent: 4 } }
    let(:parent3) { { name: 'parent3',  parent: 5 } }

    before do
      allow(ancestry_tree).to receive(:find).with(1).and_return file
      allow(ancestry_tree).to receive(:find).with(2).and_return parent1
      allow(ancestry_tree).to receive(:find).with(3).and_return parent2
      allow(ancestry_tree).to receive(:find).with(4).and_return parent3
    end

    it { is_expected.to eq %w[parent1 parent2 parent3] }
  end

  describe '#load_parents' do
    subject(:tree)    { ancestry_tree.send :tree }
    let(:nil_entries) { { 1 => nil, 2 => nil, 3 => nil } }
    let(:records) do
      [{ id: 2, name: 'file2', parent: 4 },
       { id: 3, name: 'file3', parent: 5 },
       { id: 4, name: 'file4', parent: nil }]
    end

    before do
      allow(ancestry_tree)
        .to receive(:nil_entries)
        .and_return nil_entries, nil_entries, nil_entries.slice(1)
      allow(ancestry_tree)
        .to receive(:fetch_records_for).with([1, 2, 3]).and_return records
      allow(ancestry_tree).to receive(:add_entries)
      allow(ancestry_tree).to receive(:update_entries)
      allow(ancestry_tree).to receive(:add_nil_entries)
    end

    after { ancestry_tree.send :load_parents }

    it 'adds entries for new records' do
      expect(ancestry_tree).to receive(:add_entries).with(records)
    end

    it 'updates entries of remaining nil entries (id: 1)' do
      expect(ancestry_tree).to receive(:update_entries).with([1], false)
    end

    it 'adds nil entries for parent IDs of new parents (unless nil)' do
      expect(ancestry_tree).to receive(:add_nil_entries).with([4, 5])
    end

    context 'when there are no nil entries' do
      let(:nil_entries) { [] }

      it { expect(ancestry_tree).not_to receive(:fetch_records_for) }
      it { expect(ancestry_tree).not_to receive(:add_entries) }
      it { expect(ancestry_tree).not_to receive(:update_entries) }
      it { expect(ancestry_tree).not_to receive(:add_nil_entries) }
    end
  end

  describe '#recursively_load_parents(depth:)' do
    subject { ancestry_tree.send :recursively_load_parents, depth: 7 }
    after   { subject }
    it { expect(ancestry_tree).to receive(:load_parents).exactly(7).times }
  end

  describe 'add_entries(entries)' do
    subject(:tree) { ancestry_tree.send :tree }
    let(:tree_entries) do
      { 1 => { name: 'f1_old', parent: 'p1_old' },
        2 => { name: 'f2_old', parent: 'p2_old' } }
    end
    let(:new_entries) do
      [{ id: 2, name: 'f2', parent: 'p2' },
       { id: 3, name: 'f3', parent: 'p3' },
       { id: 4, name: 'f4', parent: 'p4' }]
    end

    before { ancestry_tree.send :tree=, tree_entries }
    before { ancestry_tree.send :add_entries, new_entries }

    it 'adds new entries' do
      is_expected.to include(3 => { name: 'f3', parent: 'p3' })
      is_expected.to include(4 => { name: 'f4', parent: 'p4' })
    end

    it 'overrides existing entries on conflict' do
      is_expected.to      include(2 => { name: 'f2', parent: 'p2' })
      is_expected.not_to  include(2 => { name: 'f2_old', parent: 'p2_old' })
    end

    it 'it keeps existing entries' do
      is_expected.to include(1 => { name: 'f1_old', parent: 'p1_old' })
    end
  end

  describe '#find(id)' do
    let(:tree_entries) { { 1 => nil, 2 => false, 3 => 'value' } }

    before { ancestry_tree.send :tree=, tree_entries }

    it 'returns nil for id 1' do
      expect(ancestry_tree.send(:find, 1)).to eq nil
    end

    it 'returns nil for id 2 (false-value)' do
      expect(ancestry_tree.send(:find, 2)).to eq nil
    end

    it 'returns value for id 3' do
      expect(ancestry_tree.send(:find, 3)).to eq 'value'
    end
  end

  describe 'initialize_tree(file_ids)' do
    subject(:init_tree) { ancestry_tree.send :initialize_tree, [1, 2, 3] }
    let(:tree_entries)  { { x: 'y' } }

    before { ancestry_tree.send :tree=, tree_entries }
    before { allow(ancestry_tree).to receive(:add_nil_entries) }

    it 'resets tree' do
      init_tree
      expect(ancestry_tree.send(:tree)).to be_empty
    end

    it 'adds nil entries for file ids' do
      expect(ancestry_tree).to receive(:add_nil_entries).with([1, 2, 3])
      init_tree
    end
  end

  describe 'nil_entries' do
    subject(:nil_entries) { ancestry_tree.send :nil_entries }
    let(:tree_entries) do
      { 1 => nil,
        2 => { name: 'f1_old', parent: 'p1_old' },
        3 => nil,
        4 => { name: 'f2_old', parent: 'p2_old' },
        5 => nil }
    end

    before { ancestry_tree.send :tree=, tree_entries }

    it 'returns all entries with nil values' do
      expect(nil_entries.keys).to contain_exactly 1, 3, 5
    end
  end

  describe 'add_nil_entries(ids)' do
    subject(:tree) { ancestry_tree.send :tree }
    let(:tree_entries) do
      { 1 => { name: 'f1_old', parent: 'p1_old' },
        2 => { name: 'f2_old', parent: 'p2_old' } }
    end

    before { ancestry_tree.send :tree=, tree_entries }
    before { ancestry_tree.send :add_nil_entries, [2, 3, 4] }

    it 'adds new entries' do
      is_expected.to include(3 => nil)
      is_expected.to include(4 => nil)
    end

    it 'does not override existing entries on conflict' do
      is_expected.not_to  include(2 => nil)
      is_expected.to      include(2 => { name: 'f2_old', parent: 'p2_old' })
    end

    it 'it keeps existing entries' do
      is_expected.to include(1 => { name: 'f1_old', parent: 'p1_old' })
    end
  end

  describe 'update_entries(ids, new_value)' do
    subject(:tree) { ancestry_tree.send :tree }
    let(:tree_entries) do
      { 1 => { name: 'f1_old', parent: 'p1_old' },
        2 => { name: 'f2_old', parent: 'p2_old' } }
    end

    before { ancestry_tree.send :tree=, tree_entries }
    before { ancestry_tree.send :update_entries, [2, 3, 4], 'value' }

    it 'adds new entries' do
      is_expected.to include(3 => 'value')
      is_expected.to include(4 => 'value')
    end

    it 'does override existing entries on conflict' do
      is_expected.to      include(2 => 'value')
      is_expected.not_to  include(2 => { name: 'f2_old', parent: 'p2_old' })
    end

    it 'it keeps existing entries' do
      is_expected.to include(1 => { name: 'f1_old', parent: 'p1_old' })
    end
  end
end
