# frozen_string_literal: true

require 'models/shared_examples/being_a_file_diff_change.rb'

RSpec.describe FileDiff::Changes::Addition, type: :model do
  subject(:change)  { described_class.new(diff: diff) }
  let(:diff)        { instance_double FileDiff }

  it_should_behave_like 'being a file diff change' do
    before { allow(diff).to receive(:ancestor_path).and_return 'path' }
    let(:color)       { 'green' }
    let(:description) { 'added to path' }
    let(:tooltip)     { 'File has been added' }
    let(:type)        { 'addition' }
  end
end
