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

    context 'when diff change is :renamed' do
      let(:file_diff_change) { :renamed }
      it { is_expected.to eq 'blue darken-2' }
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

    context 'when diff changes are [:modified, :moved, :renamed]' do
      let(:file_diff_changes) { %i[modified moved renamed] }
      it { is_expected.to eq 'changed modified moved renamed' }
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

    context 'when diff change is :renamed' do
      let(:file_diff_change) { :renamed }
      it { is_expected.to be_a String }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to be_a String }
    end
  end

  describe '#sort_file_diff!s(file_diffs)' do
    subject(:method)  { helper.sort_file_diffs!(diffs) }
    let(:diffs)       { [d1, d2, d3] }
    let(:d1)          { instance_double FileDiff }
    let(:d2)          { instance_double FileDiff }
    let(:d3)          { instance_double FileDiff }

    before do
      allow(d1).to receive(:current_or_previous_snapshot).and_return 's1'
      allow(d2).to receive(:current_or_previous_snapshot).and_return 's2'
      allow(d3).to receive(:current_or_previous_snapshot).and_return 's3'
      allow(helper).to receive(:sort_order_for_files).with('s1').and_return 3
      allow(helper).to receive(:sort_order_for_files).with('s2').and_return 2
      allow(helper).to receive(:sort_order_for_files).with('s3').and_return 1
    end

    it { is_expected.to eq [d3, d2, d1] }
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

    context 'when diff change is :renamed' do
      let(:file_diff_change) { :renamed }
      it { is_expected.to eq 'blue-text text-darken-2' }
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

  describe '#text_for_file_diff_change(change, diff, ancestor_path)' do
    subject(:method) { text_for_file_diff_change(change, diff, ancestor_path) }

    let(:diff)          { instance_double FileDiff }
    let(:ancestor_path) { 'ancestor-path' }

    before { allow(diff).to receive(:previous_name).and_return 'previous' }

    context 'when diff change is :added' do
      let(:change) { :added }
      it { is_expected.to eq 'added to ancestor-path' }
    end

    context 'when diff change is :modified' do
      let(:change) { :modified }
      it { is_expected.to eq 'modified in ancestor-path' }
    end

    context 'when diff change is :moved' do
      let(:change) { :moved }
      it { is_expected.to eq 'moved to ancestor-path' }
    end

    context 'when diff change is :renamed' do
      let(:change) { :renamed }
      it { is_expected.to eq "renamed from 'previous' in ancestor-path" }
    end

    context 'when diff change is :deleted' do
      let(:change) { :deleted }
      it { is_expected.to eq 'deleted from ancestor-path' }
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

    context 'when diff change is :renamed' do
      let(:file_diff_change) { :renamed }
      it { is_expected.to eq 'File has been renamed' }
    end

    context 'when diff change is :deleted' do
      let(:file_diff_change) { :deleted }
      it { is_expected.to eq 'File has been deleted' }
    end
  end
end
