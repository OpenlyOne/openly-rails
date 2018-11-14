# frozen_string_literal: true

require 'models/shared_examples/being_notifying.rb'

RSpec.describe Revision, type: :model do
  before { skip('Model is pending deletion') }

  subject(:revision) { build_stubbed :revision }

  it_should_behave_like 'being notifying' do
    let(:notifying) { revision }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('Revision')
        .autosave(false)
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:author).class_name('Profiles::User').dependent(false)
    end
    it do
      is_expected
        .to have_many(:children)
        .class_name('Revision')
        .with_foreign_key(:parent_id)
        .dependent(:destroy)
    end

    it { is_expected.to have_many(:committed_files).dependent(:delete_all) }
    it do
      is_expected
        .to have_many(:file_diffs).inverse_of(:revision).dependent(:destroy)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:project_id) }
    it { is_expected.to have_readonly_attribute(:parent_id) }
    it { is_expected.to have_readonly_attribute(:author_id) }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:title) }

    context 'when is_published=true' do
      before  { revision.is_published = true }
      it      { is_expected.to validate_presence_of(:title) }
      it      { is_expected.not_to validate_presence_of(:summary) }
    end
  end

  describe '.create_draft_and_commit_files_for_project!(project, author)' do
    subject(:create_draft) do
      described_class
        .create_draft_and_commit_files_for_project!(project, author)
    end
    let(:draft)     { instance_double Revision }
    let(:project)   { instance_double Project }
    let(:author)    { instance_double Profiles::User }
    let(:revisions) { %w[rev1 rev2 rev3] }

    before do
      allow(described_class).to receive(:create!).and_return(draft)
      allow(draft).to receive(:commit_all_files_staged_in_project)
      allow(draft).to receive(:generate_diffs)
      allow(project).to receive(:revisions).and_return revisions
    end

    after { create_draft }

    it { is_expected.to eq draft }

    it 'calls create! with project, last revision, and author' do
      expect(described_class).to receive(:create!).with(
        project: project, parent: 'rev3', author: author
      )
    end

    it { expect(draft).to receive(:commit_all_files_staged_in_project) }
  end

  # TODO: Model is pending deletion
  xdescribe '#commit_all_files_staged_in_project' do
    subject(:commit_files) { revision.commit_all_files_staged_in_project }
    let(:columns) { %i[file_resource_id file_resource_snapshot_id revision_id] }
    let(:rows)    { [%w[f1 s1 r], %w[f2 s2 r], %w[f3 s3 r]] }
    let(:query)   { class_double ActiveRecord::Relation }

    before do
      allow(CommittedFile).to receive(:insert_from_select_query)
      collection_proxy = class_double FileResource
      allow(revision.project)
        .to receive_message_chain(
          :non_root_file_resources_in_stage,
          :with_current_snapshot
        ).and_return collection_proxy
      allow(collection_proxy)
        .to receive(:select)
        .with('r', :id, :current_snapshot_id)
        .and_return query
      allow(revision).to receive(:id).and_return 'r'
    end

    it 'calls CommittedFile.insert_from_select_query' do
      expect(CommittedFile)
        .to receive(:insert_from_select_query)
        .with(%i[revision_id file_resource_id file_resource_snapshot_id],
              query)
      commit_files
    end
  end

  describe '#file_changes' do
    subject { revision.file_changes }

    before do
      diff1 = instance_double FileDiff
      diff2 = instance_double FileDiff
      allow(revision).to receive(:file_diffs).and_return [diff1, diff2]
      allow(diff1).to receive(:changes).and_return %w[c1 c2]
      allow(diff2).to receive(:changes).and_return %w[c3]
    end

    it { is_expected.to eq %w[c1 c2 c3] }
  end

  describe '#generate_diffs' do
    subject(:generate_diffs)  { revision.generate_diffs }
    let(:calculator)          { instance_double Revision::FileDiffsCalculator }

    before do
      allow(FileDiff).to receive_message_chain(:where, :delete_all)
      allow(Revision::FileDiffsCalculator)
        .to receive_message_chain(:new, :cache_diffs!)
    end

    it { is_expected.to be true }

    it 'deletes all file diffs' do
      chain = class_double FileDiff
      expect(FileDiff)
        .to receive(:where).with(revision: revision).and_return chain
      expect(chain).to receive(:delete_all)
      subject
    end

    it 'calls Revision::FileDiffsCalculator#cache_diffs!' do
      expect(Revision::FileDiffsCalculator)
        .to receive(:new).with(revision: revision).and_return calculator
      expect(calculator).to receive(:cache_diffs!)
      subject
    end

    it 'resets file_diffs association' do
      expect(revision.file_diffs).to receive(:reset)
      subject
    end
  end

  describe '#publish(attributes_to_update)' do
    subject { revision.publish(attribute: 'update') }

    before do
      allow(revision)
        .to receive(:update)
        .with(attribute: 'update', is_published: true)
        .and_return 'return-value-of-update'
    end

    it 'returns the return value of #update' do
      is_expected.to eq 'return-value-of-update'
    end
  end

  describe '#published?' do
    before do
      allow(revision).to receive(:is_published_in_database).and_return published
    end

    context 'when published in database' do
      let(:published) { true }
      it { is_expected.to be_published }
    end

    context 'when not published in database' do
      let(:published) { false }
      it { is_expected.not_to be_published }
    end
  end

  describe '#selected_file_change_ids=(ids)' do
    let(:change1) { instance_double FileDiff::Change }
    let(:change2) { instance_double FileDiff::Change }
    let(:change3) { instance_double FileDiff::Change }

    before do
      allow(revision)
        .to receive(:file_changes).and_return [change1, change2, change3]
      allow(change1).to receive(:id).and_return 'change1'
      allow(change2).to receive(:id).and_return 'change2'
      allow(change3).to receive(:id).and_return 'change3'
    end

    after { revision.selected_file_change_ids = %w[change1 change3] }

    it 'selects change1, change3 and unselects change2' do
      expect(change1).to receive(:select!)
      expect(change2).to receive(:unselect!)
      expect(change3).to receive(:select!)
    end
  end

  describe '#apply_selected_file_changes' do
    let(:diff1) { instance_double FileDiff }
    let(:diff2) { instance_double FileDiff }
    let(:unselected_file_changes) { %w[c1 c2] }

    before do
      allow(revision)
        .to receive(:unselected_file_changes).and_return unselected_file_changes
      allow(revision).to receive(:file_diffs).and_return [diff1, diff2]
      allow(diff1).to receive(:apply_selected_changes)
      allow(diff2).to receive(:apply_selected_changes)
      allow(revision).to receive(:generate_diffs)
    end

    after { revision.send :apply_selected_file_changes }

    it 'calls apply_selected_changes on each file_diff' do
      expect(diff1).to receive(:apply_selected_changes)
      expect(diff2).to receive(:apply_selected_changes)
    end

    it 're-generates file diffs' do
      expect(revision).to receive(:generate_diffs)
    end

    context 'when all file changes are selected' do
      let(:unselected_file_changes) { [] }

      it 'does not apply selected changes or regenerate diffs' do
        expect(diff1).not_to receive(:apply_selected_changes)
        expect(diff2).not_to receive(:apply_selected_changes)
        expect(revision).not_to receive(:generate_diffs)
      end
    end
  end
end
