# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::RevisionDiff, type: :model do
  subject(:diff) { VersionControl::RevisionDiff.new(base, differentiator) }
  let(:base)            { repository.stage }
  let(:differentiator)  { repository.stage }
  let(:repository)      { build :repository }

  describe 'attributes' do
    it { should respond_to(:base) }
    it { should respond_to(:differentiator) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:rugged_repository).to(:repository) }
    it { is_expected.to delegate_method(:tree).to(:base).with_prefix(true) }
    it { is_expected.to delegate_method(:id).to(:base).with_prefix(true) }
    it do
      is_expected.to delegate_method(:id).to(:differentiator).with_prefix(true)
    end
    it do
      is_expected.to delegate_method(:tree)
        .to(:differentiator).with_prefix(true)
    end
  end

  describe '#changed_files_as_diffs', isolated_unit_test: true do
    subject(:method)  { diff.changed_files_as_diffs }
    let(:diff)        { VersionControl::RevisionDiff.new(base, differentiator) }
    let(:run_method)  { diff.changed_files_as_diffs }
    let(:file1)       { instance_double VersionControl::Files::Committed }
    let(:file2)       { instance_double VersionControl::Files::Committed }
    let(:file3)       { instance_double VersionControl::Files::Committed }
    let(:file4)       { instance_double VersionControl::Files::Committed }
    let(:diff1)       { instance_double VersionControl::FileDiff }
    let(:diff2)       { instance_double VersionControl::FileDiff }
    let(:diff3)       { instance_double VersionControl::FileDiff }

    before do
      expect(file1).to receive(:id).and_return '1'
      expect(file2).to receive(:id).and_return '2'
      expect(file3).to receive(:id).and_return '3'
      expect(file4).to receive(:id).and_return '2'
    end

    before do
      expect(diff1).to receive(:changed?).and_return false
      expect(diff2).to receive(:changed?).and_return true
      expect(diff3).to receive(:changed?).and_return true
    end

    before do
      expect(diff).to receive(:_files_of_blobs_added_to_base)
        .exactly(2).times.and_return [file1, file2]
      expect(diff).to receive(:_files_of_blobs_deleted_from_differentiator)
        .exactly(2).times.and_return [file3, file4]
      expect(diff).to receive(:files_to_diffs)
        .with([file1, file2], [file3, file4], %w[1 2 3])
        .and_return [diff1, diff2, diff3]
    end

    it 'returns [diff2, diff3]' do
      is_expected.to eq [diff2, diff3]
    end
  end

  describe '#repository', isolated_unit_test: true do
    subject(:method)  { diff.send :repository }
    let(:base)        { instance_double VersionControl::Revisions::Committed }
    let(:differentiator) do
      instance_double VersionControl::Revisions::Committed
    end
    let(:base_repo)           { instance_double VersionControl::Repository }
    let(:differentiator_repo) { instance_double VersionControl::Repository }

    before do
      allow(base).to receive(:repository).and_return base_repo
      allow(differentiator).to receive(:repository)
        .and_return differentiator_repo
    end

    it 'returns base repository' do
      is_expected.to eq base_repo
    end

    context 'when base is nil' do
      before { allow(diff).to receive(:base).and_return nil }

      it 'returns differentiator repository' do
        is_expected.to eq differentiator_repo
      end
    end
  end

  describe '#diff_file(id)' do
    subject(:method)      { diff.diff_file id }
    let(:id)              { file.id }
    let!(:file)           { create :file, parent: root }
    let(:root)            { create :file, :root, repository: repository }
    let(:differentiator)  { repository.revisions.last }
    before { create :git_revision, repository: repository }

    it { is_expected.to be_a VersionControl::FileDiff }

    it 'sets base file' do
      base_file = instance_double VersionControl::File
      allow(base.files)
        .to receive(:find_by_id).with(file.id).and_return base_file
      expect(method.base).to be base_file
    end

    it 'sets differentiator file' do
      differentiator_file = instance_double VersionControl::File
      allow(differentiator.files)
        .to receive(:find_by_id).with(file.id).and_return differentiator_file
      expect(method.differentiator).to be differentiator_file
    end

    it 'sets revision_diff to self' do
      expect(method.revision_diff).to eq diff
    end

    context 'when id exists only in base' do
      let(:id)    { file2.id }
      let(:file2) { create :file, parent: root }

      it { expect(method.base).to be_a VersionControl::File }
      it { expect(method.differentiator).to be nil }
    end

    context 'when id exists only in differentiator' do
      before { file.update parent_id: nil }

      it { expect(method.base).to be nil }
      it { expect(method.differentiator).to be_a VersionControl::File }
    end

    context 'when id exists in neither base nor differentiator' do
      let(:id) { 'non-existent-file' }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find diff for file with id: #{id}"
        )
      end
    end

    context 'when id is nil' do
      let(:id) { nil }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find diff for file with id: #{id}"
        )
      end
    end

    context 'when base is nil' do
      let(:base)  { nil }
      it          { expect { method }.not_to raise_error }
    end

    context 'when differentiator is nil' do
      let(:differentiator)  { nil }
      it                    { expect { method }.not_to raise_error }
    end
  end

  describe '#files_to_diffs(base_files, differentiator_files, filter)' do
    subject(:method) do
      diff.files_to_diffs(
        base_files,
        differentiator_files,
        filter
      )
    end
    let(:base_files) do
      [build(:file, id: 'excluded',   repository: repository),
       build(:file, id: 'base-only',  repository: repository),
       build(:file, id: 'both',       repository: repository)]
    end
    let(:differentiator_files) do
      [build(:file, id: 'both',                 repository: repository),
       build(:file, id: 'excluded-too',         repository: repository),
       build(:file, id: 'differentiator-only',  repository: repository)]
    end
    let(:filter) { ['base-only', 'both', 'differentiator-only'] }

    it 'sets revision_diff to self' do
      expect(method.map(&:revision_diff).uniq).to eq [diff]
    end

    it 'returns a file diff for every element in filter' do
      expect(method.count).to eq filter.count

      filter.each do |id|
        expect(method.detect { |diff| diff.id == id }).to be_present
      end
    end

    context 'when there are no matches for filter' do
      let(:filter)  { [] }
      it            { is_expected.to be_empty }
    end

    context 'when base_files include nil' do
      before  { base_files << nil }
      it      { expect { method }.not_to raise_error }
    end

    context 'when differentiator files include nil' do
      before  { differentiator_files << nil }
      it      { expect { method }.not_to raise_error }
    end

    context 'when base_files is nil' do
      let(:base_files)  { nil }
      it                { expect { method }.not_to raise_error }
    end

    context 'when differentiator files is nil' do
      let(:differentiator_files)  { nil }
      it                          { expect { method }.not_to raise_error }
    end

    context 'when filter is nil' do
      let(:filter)  { nil }
      it            { is_expected.to be_empty }
    end
  end

  describe '#lock_if_base_is_stage' do
    subject(:method) { diff.lock_if_base_is_stage {} }

    context 'when base is stage' do
      let(:base) { repository.stage }

      it_should_behave_like 'using repository locking' do
        let(:locker) { base }
      end

      it { expect { |b| diff.lock_if_base_is_stage(&b) }.to yield_with_no_args }
    end

    context 'when base is revision' do
      before      { create :git_revision, repository: repository }
      let(:base)  { repository.revisions.last }

      it_should_behave_like 'not using repository locking' do
        before { diff }
      end

      it { expect { |b| diff.lock_if_base_is_stage(&b) }.to yield_with_no_args }
    end
  end

  describe '#_files_of_blobs_added_to_base',
           isolated_unit_test: true do
    subject(:method)  { diff.send :_files_of_blobs_added_to_base }
    let(:file1)       { instance_double VersionControl::Files::Committed }
    let(:file2)       { instance_double VersionControl::Files::Committed }
    let(:base)        { instance_double VersionControl::Revisions::Committed }

    before do
      paths = instance_double Array
      expect(diff).to receive(:_paths_from_rugged_deltas_for)
        .with(:added_blobs).and_return paths

      base_file_collection =
        instance_double VersionControl::FileCollections::Committed
      expect(base).to receive(:files).and_return base_file_collection
      expect(base_file_collection).to receive(:find_by_path)
        .with(paths).and_return [file1, file2]
    end

    it 'returns [file, file2]' do
      is_expected.to eq [file1, file2]
    end

    it_behaves_like 'caching method call', :_files_of_blobs_added_to_base do
      subject { diff }
    end
  end

  describe '#_files_of_blobs_deleted_from_differentiator',
           isolated_unit_test: true do
    subject(:method)  { diff.send :_files_of_blobs_deleted_from_differentiator }
    let(:file1)       { instance_double VersionControl::Files::Committed }
    let(:file2)       { instance_double VersionControl::Files::Committed }
    let(:differentiator) do
      instance_double VersionControl::Revisions::Committed
    end

    context 'when differentiator is present' do
      before do
        paths = instance_double Array
        expect(diff).to receive(:_paths_from_rugged_deltas_for)
          .with(:deleted_blobs).and_return paths

        differentiator_file_collection =
          instance_double VersionControl::FileCollections::Committed
        expect(differentiator).to receive(:files)
          .and_return differentiator_file_collection
        expect(differentiator_file_collection).to receive(:find_by_path)
          .with(paths).and_return [file1, file2]
      end

      it 'returns [file, file2]' do
        is_expected.to eq [file1, file2]
      end

      it_behaves_like 'caching method call',
                      :_files_of_blobs_deleted_from_differentiator do
        subject { diff }
      end
    end

    context 'when differentiator is nil' do
      let(:differentiator) { nil }

      it 'returns []' do
        is_expected.to eq []
      end
    end
  end

  describe '#_filter_delta_file_hashes!(file_hashes)',
           isolated_unit_test: true do
    subject(:method)  { diff.send :_filter_delta_file_hashes!, hashes }
    let(:hashes)      { [root, last_rev, file1, file2, empty] }
    let(:root)        { { oid: 'sha-oid1', path: 'id-of-root/.self' } }
    let(:last_rev)    { { oid: 'sha-oid2', path: '.last-revision' } }
    let(:file1)       { { oid: 'sha-oid3', path: 'id-of-root/file1' } }
    let(:file2)       { { oid: 'sha-oid4', path: 'id-of-root/folder1/.self' } }
    let(:empty)       { { oid: '0000000000000000', path: 'id-of-root/empty' } }

    it { is_expected.to eq [file1, file2] }

    it 'filters out the root folder' do
      is_expected.not_to include root
    end

    it 'filters out the .last-revision file' do
      is_expected.not_to include last_rev
    end

    it 'filters out empty blobs' do
      is_expected.not_to include empty
    end
  end

  describe '#_paths_from_rugged_deltas_for(type_of_blobs)',
           isolated_unit_test: true do
    subject(:method) { diff.send :_paths_from_rugged_deltas_for, type_of_blobs }
    let(:delta1)  { instance_double Rugged::Diff::Delta }
    let(:delta2)  { instance_double Rugged::Diff::Delta }
    let(:delta3)  { instance_double Rugged::Diff::Delta }
    let(:delta4)  { instance_double Rugged::Diff::Delta }
    let(:file1)   { { oid: 'sha-oid1', path: 'path/to/file1' } }
    let(:file2)   { { oid: 'sha-oid2', path: 'path/to/file2' } }
    let(:file3)   { { oid: 'sha-oid3', path: 'path/to/file3' } }
    let(:file4)   { { oid: 'sha-oid3', path: 'path/to/folder/.self' } }

    before do
      expect(diff).to receive(:_rugged_deltas)
        .and_return [delta1, delta2, delta3, delta4]
      expect(delta1).to receive(file_hash_key).and_return file1
      expect(delta2).to receive(file_hash_key).and_return file2
      expect(delta3).to receive(file_hash_key).and_return file3
      expect(delta4).to receive(file_hash_key).and_return file4
      expect(diff).to receive(:_filter_delta_file_hashes!)
        .with([file1, file2, file3, file4]) { |hash| hash.delete_at 2 }
      expect(VersionControl::File).to receive(:metadata_path_to_file_path)
        .with('path/to/file1').and_return 'path/to/file1'
      expect(VersionControl::File).to receive(:metadata_path_to_file_path)
        .with('path/to/file2').and_return 'path/to/file2'
      expect(VersionControl::File).to receive(:metadata_path_to_file_path)
        .with('path/to/folder/.self').and_return 'path/to/folder'
    end

    context 'when type_of_blobs = :added_blobs' do
      let(:type_of_blobs) { :added_blobs }
      let(:file_hash_key) { :new_file }

      it "returns ['path/to/file1', 'path/to/file2', 'path/to/folder']" do
        is_expected.to eq ['path/to/file1', 'path/to/file2', 'path/to/folder']
      end

      it 'filters out file3' do
        is_expected.not_to include 'path/to/file3'
      end
    end

    context 'when type_of_blobs = :deleted_blobs' do
      let(:type_of_blobs) { :deleted_blobs }
      let(:file_hash_key) { :old_file }

      it "returns ['path/to/file1', 'path/to/file2', 'path/to/folder']" do
        is_expected.to eq ['path/to/file1', 'path/to/file2', 'path/to/folder']
      end

      it 'filters out file3' do
        is_expected.not_to include 'path/to/file3'
      end
    end
  end

  describe '#_rugged_deltas', isolated_unit_test: true do
    subject(:method)  { diff.send :_rugged_deltas }
    let(:rugged_diff) { instance_double Rugged::Diff }
    let(:deltas)      { %w[delta1 delta1] }

    before do
      expect(diff).to receive(:rugged_repository).and_return 'rugged_repo'
      expect(diff).to receive(:base_tree).and_return 'base_tree'
      expect(diff).to receive(:differentiator_tree)
        .and_return 'differentiator_tree'
      expect(Rugged::Tree).to receive(:diff)
        .with('rugged_repo', 'differentiator_tree', 'base_tree')
        .and_return rugged_diff
      expect(rugged_diff).to receive(:deltas).and_return deltas
    end

    it { is_expected.to eq deltas }
  end
end
