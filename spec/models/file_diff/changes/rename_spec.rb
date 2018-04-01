# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe FileDiff::Changes::Rename, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    before { allow(diff).to receive(:previous_name).and_return 'Old Name' }
    let(:color)       { 'blue' }
    let(:description) { "renamed from 'Old Name' in path" }
    let(:tooltip)     { 'File has been renamed' }
    let(:type)        { 'rename' }
  end
end
