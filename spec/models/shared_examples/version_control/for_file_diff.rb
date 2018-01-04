# frozen_string_literal: true

# This file contains shared examples and shared context used in
# spec/models/version_control/file_diff_spec.rb

RSpec.shared_examples 'when base is nil, returns:' do |return_value|
  let(:base)  { nil }
  it          { is_expected.to be return_value }
end

RSpec.shared_examples 'when differentiator is nil, returns:' do |return_value|
  let(:differentiator)  { nil }
  it                    { is_expected.to be return_value }
end

RSpec.shared_examples 'expected when base has no children or is nil' do
  context 'when base has no children' do
    include_context   'base has no children'
    include_examples  'returning correct diffs'
  end

  context 'when base is nil' do
    include_context   'base is nil'
    include_examples  'returning correct diffs'
  end
end

RSpec.shared_examples 'expected when differentiator has no children ' \
                      'or is nil' do
  context 'when differentiator has no children' do
    include_context   'differentiator has no children'
    include_examples  'returning correct diffs'
  end

  context 'when differentiator is nil' do
    include_context   'differentiator is nil'
    include_examples  'returning correct diffs'
  end
end

RSpec.shared_examples 'having is_or_was attribute' do |attribute|
  subject(:method)                { diff.send method_name }
  let(:method_name)               { "#{attribute}_is_or_was" }
  let(:base_attribute)            { base.send(attribute) }
  let(:differentiator_attribute)  { differentiator.send(attribute) }

  it { is_expected.to eq base_attribute }

  context 'when base is nil' do
    let(:base)  { nil }
    it          { is_expected.to eq differentiator_attribute }
  end

  context 'when base and differentiator are nil' do
    let(:base)            { nil }
    let(:differentiator)  { nil }
    it                    { is_expected.to be nil }
  end
end

RSpec.shared_examples 'locking repository only when revision base is stage' do
  context 'when revision base is stage' do
    let(:revision_base) { repository.stage }
    it                  { expect { method }.not_to raise_error }

    it_should_behave_like 'using repository locking' do
      before { diff }
    end
  end

  context 'when revision base is revision' do
    let(:revision_base) { repository.revisions.reload.last }
    it                  { expect { method }.not_to raise_error }

    it_should_behave_like 'not using repository locking' do
      before { diff }
    end
  end
end

RSpec.shared_examples 'returning correct diffs' do
  it 'returns the correct diffs' do
    expect(method.map(&:id_is_or_was)).to match_array file_ids
  end

  it 'has correct change on returned diffs' do
    expect(method).to(be_all { |file| file.send "been_#{mark_as}?" })
  end
end

RSpec.shared_context 'base has no children' do
  before { FileUtils.rm_r(Dir.glob("#{file.path}/*")) }
end

RSpec.shared_context 'base is nil' do
  before { FileUtils.rm_r(file.path) }
end

RSpec.shared_context 'differentiator has no children' do
  let(:before_file_creation_callback) do
    file
    create_revision
  end
  let(:after_file_creation_callback) { nil }
end

RSpec.shared_context 'differentiator is nil' do
  let(:before_file_creation_callback) { create_revision }
  let(:after_file_creation_callback)  { nil }
end

RSpec.shared_context 'file diff with children' do
  include_context 'file diff with files'

  # Set up files
  let(:file)      { folder }
  let(:root)      { create :file, :root, repository: repository }
  let(:folder)    { create :file, :folder, parent: root }
  let(:remain1)   { create :file, id: 'remain1', parent: folder }
  let(:remain2)   { create :file, id: 'remain2', parent: folder }
  let(:remain3)   { create :file, id: 'remain3', parent: folder }
  let(:add1)      { create :file, id: 'add1', parent: folder }
  let(:add2)      { create :file, id: 'add2', parent: folder }
  let(:delete1)   { create :file, id: 'delete1', parent: folder }
  let(:delete2)   { create :file, id: 'delete2', parent: folder }
  let(:move_out1) { create :file, id: 'move_out1', parent: folder }
  let(:move_out2) { create :file, id: 'move_out2', parent: folder }
  let(:move_in1)  { create :file, id: 'move_in1', parent: root }
  let(:move_in2)  { create :file, id: 'move_in2', parent: root }
  let(:create_files) do
    [remain1, remain2, remain3, delete1, delete2, move_out1, move_out2,
     move_in1, move_in2]
  end

  # update files
  # additions
  before  { add1 }
  before  { add2 }
  # move in files
  before  { move_in1.update parent_id: folder.id }
  before  { move_in2.update parent_id: folder.id }
  # removals
  before  { delete1.update parent_id: nil }
  before  { delete2.update parent_id: nil }
  # move out files
  before  { move_out1.update parent_id: root.id }
  before  { move_out2.update parent_id: root.id }
end

RSpec.shared_context 'file diff with files' do
  # Set the diff
  let(:diff)                    { revision_diff.diff_file(file.id) }
  let(:revision_diff)           { revision_base.diff(revision_differentiator) }
  let(:revision_base)           { repository.stage }
  let(:revision_differentiator) { repository.revisions.last }
  let(:repository)              { create :repository }

  # Before file creation callback
  before { before_file_creation_callback }

  # Set up files
  before { create_files }

  # After file creation callback
  before { after_file_creation_callback }

  # set default before/after file creation callbacks
  let(:before_file_creation_callback) { nil }
  let(:create_files)                  { nil }
  let(:after_file_creation_callback) { create_revision }
  # create revision for the repository as callback
  let(:create_revision) { create :revision, repository: repository }
end
