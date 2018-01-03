# frozen_string_literal: true

# TODO: Refactor into single file repository_locking.rb
require 'models/shared_examples/version_control/using_repository_locking.rb'
require 'models/shared_examples/version_control/not_using_repository_locking.rb'

RSpec.describe VersionControl::RevisionDiff, type: :model do
  subject(:diff) { VersionControl::RevisionDiff.new(base, differentiator) }
  let(:base)            { repository.stage }
  let(:differentiator)  { repository.stage }
  let(:repository)      { build :repository }

  describe 'attributes' do
    it { should respond_to(:base) }
    it { should respond_to(:differentiator) }
  end

  describe '#diff_file(id)' do
    subject(:method)      { diff.diff_file id }
    let(:id)              { file.id }
    let!(:file)           { create :file, parent: root }
    let(:root)            { create :file, :root, repository: repository }
    let(:differentiator)  { repository.revisions.last }
    before { create :revision, repository: repository }

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
      before { file.update(parent_id: nil, version: file.version + 1) }

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
        expect(method.detect { |diff| diff.id_is_or_was == id }).to be_present
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
      before      { create :revision, repository: repository }
      let(:base)  { repository.revisions.last }

      it_should_behave_like 'not using repository locking' do
        before { diff }
      end

      it { expect { |b| diff.lock_if_base_is_stage(&b) }.to yield_with_no_args }
    end
  end
end
