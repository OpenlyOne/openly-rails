# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe VCS::FileDiff::Changes::Modification, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double VCS::FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    let(:color)           { 'amber' }
    let(:shade)           { 'darken-4' }
    let(:description)     { 'modified in path' }
    let(:is_modification) { true }
    let(:text_color)      { 'amber-text text' }
    let(:tooltip)         { 'File has been modified' }
    let(:type)            { 'modification' }
  end

  describe '#unapply' do
    subject { change.current_snapshot }
    let(:current_snapshot) { instance_double VCS::FileSnapshot }
    let(:previous_snapshot) { instance_double VCS::FileSnapshot }

    before do
      allow(change).to receive(:current_snapshot).and_return current_snapshot
      allow(change).to receive(:previous_snapshot).and_return previous_snapshot
      allow(previous_snapshot)
        .to receive(:content_id).and_return 'previous-content-id'
      allow(previous_snapshot)
        .to receive(:content_version).and_return 'previous-content-version'
      allow(previous_snapshot)
        .to receive(:mime_type).and_return 'previous-mime-type'
      allow(previous_snapshot)
        .to receive(:remote_file_id).and_return 'previous-external-id'
      allow(previous_snapshot)
        .to receive(:thumbnail_id).and_return 'previous-thumbnail-id'
    end

    after { change.send :unapply }

    it 'resets content' do
      is_expected.to receive(:content_id=).with 'previous-content-id'
      is_expected.to receive(:content_version=).with 'previous-content-version'
      is_expected.to receive(:mime_type=).with 'previous-mime-type'
      is_expected.to receive(:remote_file_id=).with 'previous-external-id'
      is_expected.to receive(:thumbnail_id=).with 'previous-thumbnail-id'
    end
  end
end
