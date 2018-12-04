# frozen_string_literal: true

RSpec.shared_examples 'vcs: being diffing' do
  subject { diffing }

  describe 'delegations' do
    let(:version) { :current_or_previous_version }

    it { is_expected.to delegate_method(:id).to(version).with_prefix }
    it { is_expected.to delegate_method(:remote_file_id).to(version) }
    it { is_expected.to delegate_method(:link_to_remote).to(version) }
    it { is_expected.to delegate_method(:folder?).to(version) }
    it { is_expected.to delegate_method(:icon).to(version) }
    it { is_expected.to delegate_method(:mime_type).to(version) }
    it { is_expected.to delegate_method(:name).to(version) }
    it { is_expected.to delegate_method(:parent_id).to(version) }
    it { is_expected.to delegate_method(:provider).to(version) }
    it { is_expected.to delegate_method(:symbolic_mime_type).to(version) }
    it { is_expected.to delegate_method(:thumbnail_id).to(version) }
    it { is_expected.to delegate_method(:thumbnail_image).to(version) }
    it do
      is_expected.to delegate_method(:thumbnail_image_or_fallback).to(version)
    end

    it do
      is_expected
        .to delegate_method(:content_version)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:name)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:parent_id)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:file_id)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:parent_id)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:content_id)
        .to(:current_version).with_prefix(:current)
    end
    it do
      is_expected
        .to delegate_method(:plain_text_content)
        .to(:current_version).with_prefix(:current)
    end

    it do
      is_expected
        .to delegate_method(:content_version)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:name)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:parent_id)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:file_id)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:parent_id)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:content_id)
        .to(:previous_version).with_prefix(:previous)
    end
    it do
      is_expected
        .to delegate_method(:plain_text_content)
        .to(:previous_version).with_prefix(:previous)
    end

    it { is_expected.to delegate_method(:color).to(:primary_change).allow_nil }
    it do
      is_expected.to delegate_method(:text_color).to(:primary_change).allow_nil
    end
  end

  describe '#added?' do
    before do
      allow(diffing).to receive(:current_version_id).and_return 123
      allow(diffing)
        .to receive(:previous_version_id).and_return previous_version_id
    end

    context 'when previous_version_id is nil' do
      let(:previous_version_id) { nil }
      it { is_expected.to be_addition }
    end

    context 'when previous_version_id is not nil' do
      let(:previous_version_id) { 456 }
      it { is_expected.not_to be_addition }
    end
  end

  describe '#ancestor_path' do
    subject { diffing.ancestor_path }
    before  do
      allow(diffing).to receive(:first_three_ancestors).and_return ancestors
    end

    context 'when first_three_ancestors = []' do
      let(:ancestors) { [] }
      it { is_expected.to eq 'Home' }
    end

    context 'when first_three_ancestors = [anc1]' do
      let(:ancestors) { %w[anc1] }
      it { is_expected.to eq 'anc1' }
    end

    context 'when first_three_ancestors = [anc1 anc2]' do
      let(:ancestors) { %w[anc1 anc2] }
      it { is_expected.to eq 'anc2 > anc1' }
    end

    context 'when first_three_ancestors = [anc1 anc2 anc3]' do
      let(:ancestors) { %w[anc1 anc2 anc3] }
      it { is_expected.to eq '.. > anc2 > anc1' }
    end
  end

  describe '#association(association_name)' do
    let(:version) { instance_double VCS::Version }

    before do
      allow(diffing)
        .to receive(:current_or_previous_version).and_return version
    end

    after { diffing.association(association_name) }

    context 'when association name is thumbnail' do
      let(:association_name) { :thumbnail }

      it { expect(version).to receive(:association).with(:thumbnail) }
    end
  end

  describe '#change?' do
    let(:is_added)    { false }
    let(:is_deleted)  { false }
    let(:is_updated)  { false }

    before do
      allow(diffing).to receive(:addition?).and_return is_added
      allow(diffing).to receive(:deletion?).and_return is_deleted
      allow(diffing).to receive(:update?).and_return is_updated
    end

    it { is_expected.not_to be_change }

    context 'when it is added' do
      let(:is_added)  { true }
      it              { is_expected.to be_change }
    end

    context 'when it is deleted' do
      let(:is_deleted)  { true }
      it                { is_expected.to be_change }
    end

    context 'when it is updated' do
      let(:is_updated)  { true }
      it                { is_expected.to be_change }
    end
  end

  describe '#change_types' do
    subject { diffing.change_types }
    let(:is_added)    { false }
    let(:is_deleted)  { false }
    let(:is_modified) { false }
    let(:is_moved)    { false }
    let(:is_renamed)  { false }

    before do
      allow(diffing).to receive(:addition?).and_return is_added
      allow(diffing).to receive(:deletion?).and_return is_deleted
      allow(diffing).to receive(:modification?).and_return is_modified
      allow(diffing).to receive(:movement?).and_return is_moved
      allow(diffing).to receive(:rename?).and_return is_renamed
    end

    it { is_expected.to eq [] }

    context 'when it is addition, rename, and deletion' do
      let(:is_added)    { true }
      let(:is_renamed)  { true }
      let(:is_deleted)  { true }
      it { is_expected.to contain_exactly :addition, :rename, :deletion }
    end

    context 'when file is moved, rename, and modified' do
      let(:is_moved)    { true }
      let(:is_renamed)  { true }
      let(:is_modified) { true }

      it 'the first change is movement' do
        expect(subject.first).to eq :movement
      end
    end

    context 'when file is renamed and modified' do
      let(:is_renamed)  { true }
      let(:is_modified) { true }

      it 'the first change is rename' do
        expect(subject.first).to eq :rename
      end
    end
  end

  describe '#changes' do
    subject { diffing.changes }

    before do
      allow(diffing).to receive(:change_types).and_return %i[addition movement]
      allow(VCS::FileDiff::Changes::Addition)
        .to receive(:new).with(diff: diffing).and_return :c1
      allow(VCS::FileDiff::Changes::Movement)
        .to receive(:new).with(diff: diffing).and_return :c2
    end

    it { is_expected.to eq %i[c1 c2] }
  end

  describe '#content_change' do
    subject(:content_change) { diffing.content_change }

    let(:differ) { instance_double VCS::Operations::ContentDiffer }
    let(:current_content)   { 'current' }
    let(:previous_content)  { 'previous' }

    before do
      allow(diffing)
        .to receive(:current_plain_text_content).and_return current_content
      allow(diffing)
        .to receive(:previous_plain_text_content).and_return previous_content
      allow(VCS::Operations::ContentDiffer)
        .to receive(:new)
        .with(new_content: current_content, old_content: previous_content)
        .and_return differ
    end

    it { is_expected.to eq differ }

    context 'when current_content is nil' do
      let(:current_content) { nil }

      it { is_expected.to be nil }
    end

    context 'when previous_content is nil' do
      let(:previous_content) { nil }

      it { is_expected.to be nil }
    end
  end

  describe '#deletion?' do
    before do
      allow(diffing).to receive(:previous_version_id).and_return 123
      allow(diffing)
        .to receive(:current_version_id).and_return current_version_id
    end

    context 'when current_version_id is nil' do
      let(:current_version_id) { nil }
      it { is_expected.to be_deletion }
    end

    context 'when current_version_id is not nil' do
      let(:current_version_id) { 456 }
      it { is_expected.not_to be_deletion }
    end
  end

  describe 'modification?' do
    let(:current_content_id)  { 122 }
    let(:previous_content_id) { 123 }
    let(:is_updated)          { true }

    before do
      allow(diffing).to receive(:update?).and_return is_updated
      allow(diffing)
        .to receive(:current_content_id).and_return current_content_id
      allow(diffing)
        .to receive(:previous_content_id).and_return previous_content_id
    end

    it { expect(diffing).to be_modification }

    context 'when content versions are the same' do
      let(:current_content_id)  { 79 }
      let(:previous_content_id) { 79 }

      it { expect(diffing).not_to be_modification }
    end

    context 'when it is not updated' do
      let(:is_updated) { false }
      it { expect(diffing).not_to be_modification }
    end
  end

  describe 'movement?' do
    let(:current_parent_id)   { 51 }
    let(:previous_parent_id)  { 99 }
    let(:is_updated)          { true }

    before do
      allow(diffing).to receive(:update?).and_return is_updated
      allow(diffing).to receive(:current_parent_id).and_return current_parent_id
      allow(diffing)
        .to receive(:previous_parent_id).and_return previous_parent_id
    end

    it { expect(diffing).to be_movement }

    context 'when parents are the same' do
      let(:current_parent_id)   { 100 }
      let(:previous_parent_id)  { 100 }

      it { expect(diffing).not_to be_movement }
    end

    context 'when it is not updated' do
      let(:is_updated) { false }
      it { expect(diffing).not_to be_movement }
    end
  end

  describe '#primary_change' do
    subject { diffing.primary_change }
    before  { allow(diffing).to receive(:changes).and_return %w[c1 c2 c3] }
    it      { is_expected.to be 'c1' }
  end

  describe 'rename?' do
    let(:current_name)  { 'File A' }
    let(:previous_name) { 'File B' }
    let(:is_updated)    { true }

    before do
      allow(diffing).to receive(:update?).and_return is_updated
      allow(diffing).to receive(:current_name).and_return current_name
      allow(diffing).to receive(:previous_name).and_return previous_name
    end

    it { expect(diffing).to be_rename }

    context 'when names are the same' do
      let(:current_name)   { 'name' }
      let(:previous_name)  { 'name' }

      it { expect(diffing).not_to be_rename }
    end

    context 'when it is not updated' do
      let(:is_updated) { false }
      it { expect(diffing).not_to be_rename }
    end
  end

  describe '#update?' do
    let(:is_added)              { false }
    let(:is_deleted)            { false }
    let(:current_version_id)   { 1 }
    let(:previous_version_id)  { 2 }

    before do
      allow(diffing).to receive(:addition?).and_return is_added
      allow(diffing).to receive(:deletion?).and_return is_deleted
      allow(diffing)
        .to receive(:current_version_id).and_return current_version_id
      allow(diffing)
        .to receive(:previous_version_id).and_return previous_version_id
    end

    it { is_expected.to be_update }

    context 'when version IDs are the same' do
      let(:current_version_id)   { 13 }
      let(:previous_version_id)  { 13 }
      it { is_expected.not_to be_update }
    end

    context 'when diffing is added' do
      let(:is_added) { true }
      it { is_expected.not_to be_update }
    end

    context 'when diffing is deleted' do
      let(:is_deleted) { true }
      it { is_expected.not_to be_update }
    end
  end
end
