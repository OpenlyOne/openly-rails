# frozen_string_literal: true

RSpec.describe FileDiffHelper, type: :helper do
  let(:file_diff) do
    VersionControl::FileDiff.new(revision_diff, base, differentiator)
  end
  let(:revision_diff)   { instance_double VersionControl::RevisionDiff }
  let(:base)            { build :file }
  let(:differentiator)  { base }

  describe '#color_for_file_diff_change(file_diff_change)' do
    subject(:method) { color_for_file_diff_change(file_diff_change) }

    context 'when diff change is :added' do
      let(:file_diff_change) { :added }
      it { is_expected.to eq 'green darken-2' }
    end

    context 'when diff change is :modified' do
      let(:file_diff_change) { :modified }
      it { is_expected.to eq 'amber darken-4' }
    end

    context 'when diff change is :moved' do
      let(:file_diff_change) { :moved }
      it { is_expected.to eq 'purple darken-2' }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to eq 'red darken-2' }
    end
  end

  describe '#html_class_for_file_diff_changes(file_diff_changes)' do
    subject(:method) { html_class_for_file_diff_changes(file_diff_changes) }

    context 'when diff changes are [:added]' do
      let(:file_diff_changes) { [:added] }
      it { is_expected.to eq 'changed added' }
    end

    context 'when diff changes are [:modified]' do
      let(:file_diff_changes) { [:modified] }
      it { is_expected.to eq 'changed modified' }
    end

    context 'when diff changes are [:moved]' do
      let(:file_diff_changes) { [:moved] }
      it { is_expected.to eq 'changed moved' }
    end

    context 'when diff changes are [:deleted]' do
      let(:file_diff_changes) { [:deleted] }
      it { is_expected.to eq 'changed deleted' }
    end

    context 'when diff changes are [:modified, :moved]' do
      let(:file_diff_changes) { %i[modified moved] }
      it { is_expected.to eq 'changed modified moved' }
    end

    context 'when diff changes are []' do
      let(:file_diff_changes) { [] }
      it { is_expected.to eq 'unchanged' }
    end
  end

  describe '#icon_for_file_diff_change(file_diff_change)' do
    subject(:method) { icon_for_file_diff_change(file_diff_change) }

    context 'when diff change is :added' do
      let(:file_diff_change) { :added }
      it { is_expected.to be_a String }
    end

    context 'when diff change is :modified' do
      let(:file_diff_change) { :modified }
      it { is_expected.to be_a String }
    end

    context 'when diff change is :moved' do
      let(:file_diff_change) { :moved }
      it { is_expected.to be_a String }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to be_a String }
    end
  end

  describe '#sort_file_diffs(file_diffs)' do
    subject(:method) { sort_file_diffs!(file_diffs) }
    let(:file_diffs) do
      [
        VersionControl::FileDiff.new(nil, dir1,   dir1),
        VersionControl::FileDiff.new(nil, dir2,   nil),
        VersionControl::FileDiff.new(nil, nil,    dir3),
        VersionControl::FileDiff.new(nil, file1,  file1),
        VersionControl::FileDiff.new(nil, file2,  nil),
        VersionControl::FileDiff.new(nil, nil,    file3)
      ].shuffle
    end
    let(:dir1)        { build :file, :folder, name: 'A Folder' }
    let(:dir2)        { build :file, :folder, name: 'Homework' }
    let(:dir3)        { build :file, :folder, name: 'Something Great' }
    let(:file1)       { build :file, name: 'A Funny File' }
    let(:file2)       { build :file, name: 'Financials' }
    let(:file3)       { build :file, name: 'Potato Soup Recipe' }

    it 'sorts file diffs in correct order' do
      expect(method.map(&:file_is_or_was))
        .to eq [dir1, dir2, dir3, file1, file2, file3]
    end

    it 'modifies the files parameter' do
      expect { subject }.to(change { file_diffs })
    end

    it 'puts directories first' do
      subject
      expect(file_diffs[0..2].map(&:directory?)).to eq [true, true, true]
      expect(file_diffs[3..5].map(&:directory?)).to eq [false, false, false]
    end

    it 'puts file diffs in alphabetical order' do
      subject
      last_file_diff = file_diffs[0]
      file_diffs[1..2].each do |file_diff|
        # expect file name to come later (alphabetically) than last file's name
        expect(file_diff.name > last_file_diff.name).to be true

        # set last_file_diffs to current file_diffs for next comparison
        last_file_diff = file_diff
      end

      last_file_diff = file_diffs[3]
      file_diffs[4..5].each do |file_diff|
        # expect file name to come later (alphabetically) than last file's name
        expect(file_diff.name > last_file_diff.name).to be true

        # set last_file_diffs to current file_diffs for next comparison
        last_file_diff = file_diff
      end
    end
  end

  describe '#text_color_for_file_diff_change(file_diff_change)' do
    subject(:method) { text_color_for_file_diff_change(file_diff_change) }

    context 'when diff change is :added' do
      let(:file_diff_change) { :added }
      it { is_expected.to eq 'green-text text-darken-2' }
    end

    context 'when diff change is :modified' do
      let(:file_diff_change) { :modified }
      it { is_expected.to eq 'amber-text text-darken-4' }
    end

    context 'when diff change is :moved' do
      let(:file_diff_change) { :moved }
      it { is_expected.to eq 'purple-text text-darken-2' }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to eq 'red-text text-darken-2' }
    end

    context 'when diff change is other' do
      let(:file_diff_change) { :other }
      it { is_expected.to eq nil }
    end

    context 'when diff change is nil' do
      let(:file_diff_change) { nil }
      it { is_expected.to eq nil }
    end
  end

  describe '#tooltip_for_file_diff_change(file_diff_change)' do
    subject(:method) { tooltip_for_file_diff_change(file_diff_change) }

    context 'when diff change is :added' do
      let(:file_diff_change) { :added }
      it { is_expected.to eq 'File has been added' }
    end

    context 'when diff change is :modified' do
      let(:file_diff_change) { :modified }
      it { is_expected.to eq 'File has been modified' }
    end

    context 'when diff change is :moved' do
      let(:file_diff_change) { :moved }
      it { is_expected.to eq 'File has been moved' }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to eq 'File has been deleted' }
    end
  end
end
