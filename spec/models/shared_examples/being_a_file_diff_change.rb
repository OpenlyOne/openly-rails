# frozen_string_literal: true

RSpec.shared_examples 'being a file diff change' do
  let(:shade) { 'darken-2' }

  describe 'delegations' do
    it { is_expected.to delegate_method(:ancestor_path).to(:diff) }
    it do
      is_expected.to delegate_method(:current_or_previous_snapshot).to(:diff)
    end
    it { is_expected.to delegate_method(:external_id).to(:diff) }
    it { is_expected.to delegate_method(:icon).to(:diff) }
    it { is_expected.to delegate_method(:name).to(:diff) }
    it { is_expected.to delegate_method(:symbolic_mime_type).to(:diff) }
  end

  describe '#color' do
    subject { change.color }
    it      { is_expected.to eq "#{color} #{shade}" }
  end

  describe '#description' do
    subject { change.description }
    it      { is_expected.to eq description }
  end

  describe '#indicator_icon' do
    it { is_expected.to respond_to(:indicator_icon) }
  end

  describe '#text_color' do
    subject { change.text_color }
    it      { is_expected.to eq "#{color}-text text-#{shade}" }
  end

  describe '#tooltip' do
    subject { change.tooltip }
    it      { is_expected.to eq tooltip }
  end

  describe '#type' do
    subject { change.type }
    it      { is_expected.to eq type }
  end
end
