# frozen_string_literal: true

RSpec.shared_examples 'being a file diff change' do
  let(:shade)           { 'darken-2' }
  let(:is_addition)     { false }
  let(:is_deletion)     { false }
  let(:is_modification) { false }
  let(:is_movement)     { false }
  let(:is_rename)       { false }

  describe 'delegations' do
    it { is_expected.to delegate_method(:ancestor_path).to(:diff) }
    it { is_expected.to delegate_method(:current_version).to(:diff) }
    it { is_expected.to respond_to(:current_version=) }
    it do
      is_expected.to delegate_method(:current_or_previous_version).to(:diff)
    end
    it { is_expected.to delegate_method(:file_id).to(:diff) }
    it { is_expected.to delegate_method(:file_resource_id).to(:diff) }
    it { is_expected.to delegate_method(:hashed_file_id).to(:diff) }
    it { is_expected.to delegate_method(:icon).to(:diff) }
    it { is_expected.to delegate_method(:name).to(:diff) }
    it { is_expected.to delegate_method(:parent_id).to(:diff) }
    it { is_expected.to delegate_method(:previous_parent_id).to(:diff) }
    it { is_expected.to delegate_method(:previous_version).to(:diff) }
    it { is_expected.to delegate_method(:symbolic_mime_type).to(:diff) }
    it { is_expected.to delegate_method(:revision).to(:diff) }
    it { is_expected.to delegate_method(:content_change).to(:diff) }

    it do
      is_expected.to delegate_method(:unselected_file_changes).to(:revision)
    end
  end

  describe '#initialize' do
    it 'marks change as selected' do
      expect(change).to be_selected
    end
  end

  describe '#addition' do
    it { expect(change.addition?).to be is_addition }
  end

  describe '#apply' do
    after { change.apply }

    context 'when change is selected' do
      before  { change.select! }
      it      { is_expected.not_to receive(:unapply) }
    end

    context 'when change is selected' do
      before  { change.unselect! }
      it      { is_expected.to receive(:unapply) }
    end
  end

  describe '#color' do
    subject { change.color }
    it      { is_expected.to eq "#{color} #{shade}" }
  end

  describe '#deletion' do
    it { expect(change.deletion?).to be is_deletion }
  end

  describe '#description' do
    subject { change.description }
    it      { is_expected.to eq description }
  end

  describe '#id' do
    subject { change.id }
    before  { allow(diff).to receive(:hashed_file_id).and_return 'hash-ID' }
    it      { is_expected.to eq "hash-ID_#{type}" }
  end

  describe '#indicator_icon' do
    it { is_expected.to respond_to(:indicator_icon) }
  end

  describe '#modification' do
    it { expect(change.modification?).to be is_modification }
  end

  describe '#movement' do
    it { expect(change.movement?).to be is_movement }
  end

  describe '#rename' do
    it { expect(change.rename?).to be is_rename }
  end

  describe '#text_color' do
    subject { change.text_color }
    it      { is_expected.to eq "#{color}-text text-#{shade}" }
  end

  describe '#tooltip' do
    subject { change.tooltip }
    it      { is_expected.to eq tooltip }
  end

  describe '#select!' do
    before  { change.select! }
    it      { is_expected.to be_selected }
  end

  describe '#type' do
    subject { change.type }
    it      { is_expected.to eq type }
  end

  describe '#unselect!' do
    before  { change.unselect! }
    it      { is_expected.not_to be_selected }
  end
end
