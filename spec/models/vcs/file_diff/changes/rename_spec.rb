# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe VCS::FileDiff::Changes::Rename, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double VCS::FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    before { allow(diff).to receive(:previous_name).and_return 'Old Name' }
    let(:color)       { 'blue' }
    let(:description) { "renamed from 'Old Name' in path" }
    let(:is_rename)   { true }
    let(:tooltip)     { 'File has been renamed' }
    let(:type)        { 'rename' }
  end

  describe '#unapply' do
    subject { change.current_version }
    let(:current_version) { instance_double VCS::Version }
    let(:previous_version) { instance_double VCS::Version }

    before do
      allow(change).to receive(:current_version).and_return current_version
      allow(change).to receive(:previous_version).and_return previous_version
      allow(previous_version).to receive(:name).and_return 'previous-name'
    end

    after { change.send :unapply }
    it    { is_expected.to receive(:name=).with 'previous-name' }
  end
end
