# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe VCS::FileDiff::Changes::Deletion, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double VCS::FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    let(:color)       { 'red' }
    let(:description) { 'deleted from path' }
    let(:is_deletion) { true }
    let(:tooltip)     { 'File has been deleted' }
    let(:type)        { 'deletion' }
  end

  describe '#unapply' do
    before do
      allow(change).to receive(:previous_snapshot).and_return 'previous-snap'
    end
    after { change.send :unapply }
    it    { is_expected.to receive(:current_snapshot=).with('previous-snap') }
  end
end
