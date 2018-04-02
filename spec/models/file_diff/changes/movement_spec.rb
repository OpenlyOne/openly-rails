# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe FileDiff::Changes::Movement, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    let(:color)       { 'purple' }
    let(:description) { 'moved to path' }
    let(:is_movement) { true }
    let(:tooltip)     { 'File has been moved' }
    let(:type)        { 'movement' }
  end

  describe '#unapply' do
    subject { change.current_snapshot }
    let(:current_snapshot) { instance_double FileResource::Snapshot }
    let(:previous_snapshot) { instance_double FileResource::Snapshot }

    before do
      allow(change).to receive(:current_snapshot).and_return current_snapshot
      allow(change).to receive(:previous_snapshot).and_return previous_snapshot
      allow(previous_snapshot)
        .to receive(:parent_id).and_return 'previous-parent-id'
    end

    after { change.send :unapply }
    it    { is_expected.to receive(:parent_id=).with 'previous-parent-id' }
  end
end
